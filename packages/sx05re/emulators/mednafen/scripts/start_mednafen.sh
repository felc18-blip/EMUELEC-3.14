#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS-Elite-Edition: simplified launcher
#
# Usage: start_mednafen.sh <ROM> [<CORE>] [<PLATFORM>]
#   <CORE> may be auto-detected from PLATFORM if not given.
#
# Per-core video pipeline:
#   - psx → software (gl4es interlace handling for PSX is buggy on Mali-450)
#   - everything else → opengl + gl4es preload (HW accelerated via Mali)
#
# Input:
#   gptokeyb wraps the gamepad → keyboard so we sidestep mednafen's per-pad
#   joystick GUID/axis mess (legacy USB pads with BTN_TRIGGER 288–299 don't
#   map cleanly otherwise).

. /etc/profile

set -x

export MEDNAFEN_HOME=/storage/.config/mednafen
export MEDNAFEN_CONFIG=/usr/config/mednafen/mednafen.template
GPTK_CFG=/usr/config/mednafen/mednafen.gptk

mkdir -p "$MEDNAFEN_HOME"

if [ ! -f "$MEDNAFEN_HOME/mednafen.cfg" ]; then
    /usr/bin/bash /usr/bin/mednafen_gen_config.sh
fi

ROM="${1}"
CORE="${2}"
PLATFORM="${3}"

# Map ES platform → mednafen core when CORE is empty
if [ -z "$CORE" ] && [ -n "$PLATFORM" ]; then
    case "$PLATFORM" in
        nes|fds|famicom)                    CORE=nes ;;
        snes|sfc|snesh|snesm)               CORE=snes_faust ;;
        gb|gameboy)                         CORE=gb ;;
        gba|gameboyadvance)                 CORE=gba ;;
        gg|gamegear)                        CORE=gg ;;
        sms|mastersystem)                   CORE=sms ;;
        megadrive|genesis|md|sega32x)       CORE=md ;;
        pcengine|tg16|pce|tg-16|turbografx) CORE=pce_fast ;;
        ngp|ngpc|neogeopocket|neogeopocketcolor) CORE=ngp ;;
        wonderswan|wonderswancolor|ws|wsc)  CORE=wswan ;;
        psx|psone|playstation)              CORE=psx ;;
        ss|saturn)                          CORE=ss ;;
        lynx|atarilynx)                     CORE=lynx ;;
        vb|virtualboy)                      CORE=vb ;;
        pcfx)                               CORE=pcfx ;;
        *)                                  CORE="$PLATFORM" ;;
    esac
fi

# Save / state paths follow EmuELEC layout (silently no-op if keys absent)
if [ -n "$PLATFORM" ]; then
    sed -i "s|^filesys.path_sav .*|filesys.path_sav /storage/roms/${PLATFORM}|" "$MEDNAFEN_HOME/mednafen.cfg" 2>/dev/null
    sed -i "s|^filesys.path_savbackup.*|filesys.path_savbackup /storage/roms/${PLATFORM}|" "$MEDNAFEN_HOME/mednafen.cfg" 2>/dev/null
    sed -i "s|^filesys.path_state.*|filesys.path_state /storage/roms/savestates/${PLATFORM}|" "$MEDNAFEN_HOME/mednafen.cfg" 2>/dev/null
fi

# Firmware path: EmuELEC stores bios per-platform under /storage/roms/bios/<plat>/.
# Mednafen looks up files like gba_bios.bin, scph5500.bin, etc. by name inside
# filesys.path_firmware — so we point it at the matching subdir if present
# (falls back to /storage/roms/bios root, where Saturn's saturn_bios.bin lives).
BIOS_ROOT=/storage/roms/bios
case "$CORE" in
    gba)  BIOS_DIR="$BIOS_ROOT/gba"  ;;
    ss)   BIOS_DIR="$BIOS_ROOT/saturn" ;;
    psx)  BIOS_DIR="$BIOS_ROOT/psx"  ;;
    pcfx) BIOS_DIR="$BIOS_ROOT/pcfx" ;;
    *)    BIOS_DIR="$BIOS_ROOT"      ;;
esac
[ -d "$BIOS_DIR" ] || BIOS_DIR="$BIOS_ROOT"
sed -i "s|^filesys.path_firmware .*|filesys.path_firmware ${BIOS_DIR}|" "$MEDNAFEN_HOME/mednafen.cfg" 2>/dev/null

# Pick video pipeline per core
case "$CORE" in
    psx)
        # PSX has interlace artifacts under gl4es+Mali — software is cleaner.
        VIDEO_DRIVER="softfb"
        unset LD_PRELOAD
        ;;
    *)
        # gl4es libEGL is shipped at /usr/lib/libEGL_gl4es.so.1 (NOT replacing
        # the system /usr/lib/libEGL.so.1 -> libMali.so symlink). On the
        # device /usr is read-only at runtime, so we also accept the writable
        # /storage path as a fallback (used during development).
        VIDEO_DRIVER="opengl"
        export LIBGL_ES=2
        export LIBGL_GL=21
        # Prefer NextOS-built SDL2/SDL3 (with mali-fbdev fixes) when present
        if [ -d /storage/mednafen-libs ]; then
            export LD_LIBRARY_PATH="/storage/mednafen-libs:${LD_LIBRARY_PATH}"
        fi
        if [ -f /usr/lib/libEGL_gl4es.so.1 ]; then
            export LD_PRELOAD="/usr/lib/libEGL_gl4es.so.1:/usr/lib/libGL.so.1"
        elif [ -f /storage/libEGL_gl4es.so.1 ]; then
            export LD_PRELOAD="/storage/libEGL_gl4es.so.1:/usr/lib/libGL.so.1"
        else
            echo "WARN: libEGL_gl4es.so.1 not found; falling back to softfb" >&2
            VIDEO_DRIVER="softfb"
            unset LD_PRELOAD
        fi
        ;;
esac

# stretch=full preenche toda a tela (perde aspect ratio); use 'aspect' pra manter proporção
STRETCH="${STRETCH:-full}"
ARGS=( -fs 1 -force_module "$CORE" -video.driver "$VIDEO_DRIVER" "-${CORE}.stretch" "$STRETCH" )

# /usr/bin/mednafen at runtime; /tmp/mednafen during dev tests
MEDNAFEN_BIN="/usr/bin/mednafen"
[ -x /tmp/mednafen ] && MEDNAFEN_BIN="/tmp/mednafen"

# gptokeyb: gamepad → keyboard
USER_GPTK="$MEDNAFEN_HOME/mednafen.gptk"
[ -f "$USER_GPTK" ] && GPTK_CFG="$USER_GPTK"

cleanup() {
    # Mata gptokeyb órfão + qualquer leftover do start_mednafen.
    # Sem isso, gptokeyb fica vivo após Start+Select kill do mednafen,
    # intercepta input do gamepad no ES e parece "travamento".
    pkill -9 -f "gptokeyb.*mednafen" 2>/dev/null
    pkill -9 -f "gptokeyb 1 mednafen" 2>/dev/null
}
trap cleanup EXIT INT TERM HUP

if [ -x /usr/bin/gptokeyb ] && [ -f "$GPTK_CFG" ]; then
    pkill -9 -f "gptokeyb.*mednafen" 2>/dev/null
    # IMPORTANTE: unset EMUELEC antes de spawnar gptokeyb. Quando essa env
    # está set (sempre, via /etc/profile.d/99-emuelec.conf), o gptokeyb
    # ativa emuelec_override=true e desativa o handler de BACK (Select)
    # como hotkey de kill_mode — Start+Select nunca mata mednafen.
    env -u EMUELEC /usr/bin/gptokeyb 1 mednafen -c "$GPTK_CFG" &
    GPTK_PID=$!
    sleep 0.5
fi

# NÃO usar exec aqui — o exec substitui o bash pai pelo mednafen e o
# trap cleanup não dispara mais. Quando gptokeyb (kill_mode 1) mata
# mednafen via Start+Select, o gptokeyb órfão + qualquer side-process
# sobreviveriam, interceptando input do gamepad no ES = "tela travada".
# Rodar como child + wait + trap garante cleanup completo.
"$MEDNAFEN_BIN" "${ARGS[@]}" "$ROM"
RC=$?
cleanup
exit ${RC}
