#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS launcher for melonDS standalone (Qt5 + ScreenPanelNative + soft 3D).
# Invoked from emuelecRunEmu.sh — that script already calls
# set_kill_keys "melonDS" before us.

. /etc/profile

MELON_CFG_DIR="/storage/.config/emuelec/configs/melonds"
MELON_BIOS_DIR="/storage/roms/bios"
ROM="${1}"
PLATFORM="${2:-nds}"
GAME=$(basename "${ROM}")

init_game

# First-time install: seed the config dir if empty.
if [ ! -d "${MELON_CFG_DIR}" ] && [ -d /usr/config/emuelec/configs/melonds ]; then
    mkdir -p "${MELON_CFG_DIR}"
    cp -rf /usr/config/emuelec/configs/melonds/* "${MELON_CFG_DIR}/" 2>/dev/null || true
fi
mkdir -p "${MELON_CFG_DIR}"

# Per-game CPU core override via emustation (Y → Avançado → Cores)
CORES=$(get_ee_setting "cores" "${PLATFORM}" "${GAME}")
case "${CORES}" in
    little) EMUPERF="${SLOW_CORES}" ;;
    big)    EMUPERF="${FAST_CORES}" ;;
    *)      unset EMUPERF ;;
esac

# Qt eglfs platform plugin needs to know which framebuffer device to use
# and that we want fullscreen. The eglfs plugin defaults usually work on
# Mali-Amlogic, but force them explicitly so we don't depend on env state.
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_HIDECURSOR=1
export QT_QPA_EGLFS_FB=/dev/fb0

# melonDS expects bios files (bios7.bin, bios9.bin, firmware.bin) in
# CWD or in the EmuDirectory. Symlink them from /storage/roms/bios so
# the user can drop those files there once and they get picked up.
mkdir -p "${MELON_BIOS_DIR}"
for f in bios7.bin bios9.bin firmware.bin dsi_bios7.bin dsi_bios9.bin dsi_firmware.bin dsi_nand.bin; do
    if [ -f "${MELON_BIOS_DIR}/${f}" ] && [ ! -e "${MELON_CFG_DIR}/${f}" ]; then
        ln -sf "${MELON_BIOS_DIR}/${f}" "${MELON_CFG_DIR}/${f}"
    fi
done

cd "${MELON_CFG_DIR}"
${EMUPERF} /usr/bin/melonDS "${ROM}"
RET=$?

end_game
exit ${RET}
