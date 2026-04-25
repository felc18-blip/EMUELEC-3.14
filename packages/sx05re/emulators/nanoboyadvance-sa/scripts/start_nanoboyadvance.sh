#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS launcher for NanoBoyAdvance standalone (GLES2 SDL frontend).
# Invoked from emuelecRunEmu.sh — that script already calls
# set_kill_keys "NanoBoyAdvance" before us, so we don't repeat it.

. /etc/profile

NBA_CFG_DIR="/storage/.config/emuelec/configs/nanoboyadvance"
NBA_BIOS_DIR="/storage/roms/bios/gba"
ROM="${1}"
PLATFORM="${2:-gba}"
GAME=$(basename "${ROM}")

init_game

# First-time install: copy bundled defaults to /storage so the user can edit
# config.toml / keymap.toml without losing them on update.
if [ ! -d "${NBA_CFG_DIR}" ] && [ -d /usr/config/emuelec/configs/nanoboyadvance ]; then
    mkdir -p "${NBA_CFG_DIR}"
    cp -rf /usr/config/emuelec/configs/nanoboyadvance/* "${NBA_CFG_DIR}/"
fi

# Make sure the GBA bios folder exists. The open-source ReGBA bios is shipped
# in /usr/config/emuelec/configs/nanoboyadvance/gba_bios.bin on first install
# (downloaded at package build time); seed /storage/roms/bios/gba with it if
# the user hasn't dropped a real bios there yet.
mkdir -p "${NBA_BIOS_DIR}"
if [ ! -f "${NBA_BIOS_DIR}/gba_bios.bin" ] && \
   [ -f "${NBA_CFG_DIR}/gba_bios.bin" ]; then
    cp -f "${NBA_CFG_DIR}/gba_bios.bin" "${NBA_BIOS_DIR}/gba_bios.bin"
fi

# Per-game CPU core override via emustation (Y → Avançado → Cores)
CORES=$(get_ee_setting "cores" "${PLATFORM}" "${GAME}")
case "${CORES}" in
    little) EMUPERF="${SLOW_CORES}" ;;
    big)    EMUPERF="${FAST_CORES}" ;;
    *)      unset EMUPERF ;;
esac

${EMUPERF} /usr/bin/NanoBoyAdvance --fullscreen "${ROM}"
RET=$?

end_game
exit ${RET}
