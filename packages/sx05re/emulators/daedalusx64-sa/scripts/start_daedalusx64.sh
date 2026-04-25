#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS launcher for DaedalusX64 standalone (GLES2 port).
# Invoked from emuelecRunEmu.sh — that script has already called
# set_kill_keys "daedalus" before us, so we don't repeat it.

. /etc/profile

DX_DIR="/storage/.config/DaedalusX64"
ROM="${1}"
PLATFORM="${2:-n64}"
GAME=$(basename "${ROM}")

init_game

# First-time install fallback if user wiped /storage copy
if [ ! -d "${DX_DIR}" ] && [ -d /usr/config/DaedalusX64 ]; then
    cp -r /usr/config/DaedalusX64 /storage/.config/
fi

# Rom/save symlinks (idempotent — rm -rf so dir leftovers from old runs go too)
mkdir -p /storage/roms/savestates/n64/daedalus
rm -rf "${DX_DIR}/Roms" "${DX_DIR}/SavesGames" "${DX_DIR}/SaveStates"
ln -sf /storage/roms/n64                       "${DX_DIR}/Roms"
ln -sf /storage/roms/n64                       "${DX_DIR}/SavesGames"
ln -sf /storage/roms/savestates/n64/daedalus   "${DX_DIR}/SaveStates"

# Per-game CPU core override via emustation (Y → Avançado → Cores)
CORES=$(get_ee_setting "cores" "${PLATFORM}" "${GAME}")
case "${CORES}" in
    little) EMUPERF="${SLOW_CORES}" ;;
    big)    EMUPERF="${FAST_CORES}" ;;
    *)      unset EMUPERF ;;
esac

# Daedalus only opens .n64/.z64/.v64 — extract archives transparently
case "${ROM,,}" in
    *.zip)
        SCRATCH=/tmp/dx_rom
        rm -rf "${SCRATCH}"; mkdir -p "${SCRATCH}"
        unzip -o "${ROM}" -d "${SCRATCH}" >/dev/null
        ROM=$(find "${SCRATCH}" -maxdepth 2 -type f \
                \( -iname '*.n64' -o -iname '*.z64' -o -iname '*.v64' \) \
                | head -1)
        if [ -z "${ROM}" ]; then
            echo "ERROR: no .n64/.z64/.v64 inside the ZIP" >&2
            end_game
            exit 1
        fi
        ;;
    *.7z|*.7Z)
        SCRATCH=/tmp/dx_rom
        rm -rf "${SCRATCH}"; mkdir -p "${SCRATCH}"
        7z x -o"${SCRATCH}" "${ROM}" >/dev/null
        ROM=$(find "${SCRATCH}" -maxdepth 2 -type f \
                \( -iname '*.n64' -o -iname '*.z64' -o -iname '*.v64' \) \
                | head -1)
        if [ -z "${ROM}" ]; then
            echo "ERROR: no .n64/.z64/.v64 inside the 7z" >&2
            end_game
            exit 1
        fi
        ;;
esac

cd "${DX_DIR}"
${EMUPERF} "${DX_DIR}/daedalus" "${ROM}"

end_game
