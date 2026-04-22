#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
# Adapted for NextOS Elite Edition / EmuELEC

. /etc/profile

GAME_DIR="/storage/roms/pico-8/"
BIOS_DIR="/storage/roms/bios/pico-8/"
SHARE_DIR="/usr/share/pico-8/"

# Detect architecture
case $(uname -m) in
  aarch64)
    STATIC_BIN="pico8_64"
    HW_ARCH="aarch64"
  ;;
  armv7l|armhf)
    STATIC_BIN="pico8_dyn"
    HW_ARCH="armv7l"
  ;;
  *)
    STATIC_BIN="pico8_dyn"
    HW_ARCH="$(uname -m)"
  ;;
esac

# Check Splore vs direct cart launch
shopt -s nocasematch
if [[ "${1}" == *splore* ]]; then
  OPTIONS="-splore"
else
  OPTIONS="-run"
  CART="${1}"
fi
shopt -u nocasematch

# Integer scale setting
INTEGER_SCALE=$(get_ee_setting pico-8.integerscale 2>/dev/null)
if [ "${INTEGER_SCALE}" = "1" ]; then
  OPTIONS="${OPTIONS} -pixel_perfect 1"
fi

# First boot: copy binaries from /usr/share/pico-8 to /storage/roms/pico-8/
if [ -f "${SHARE_DIR}/${STATIC_BIN}" ] && [ ! -f "${GAME_DIR}/${STATIC_BIN}" ]; then
  mkdir -p "${GAME_DIR}"
  cp "${SHARE_DIR}"/* "${GAME_DIR}/" 2>/dev/null
  chmod +x "${GAME_DIR}/${STATIC_BIN}"
fi

# Find the binary
if [ -d "${GAME_DIR}/${HW_ARCH}" ] && [ -f "${GAME_DIR}/${HW_ARCH}/${STATIC_BIN}" ]; then
  LAUNCH_DIR="${GAME_DIR}/${HW_ARCH}"
elif [ -f "${GAME_DIR}/${STATIC_BIN}" ]; then
  LAUNCH_DIR="${GAME_DIR}"
elif [ -f "${BIOS_DIR}/${STATIC_BIN}" ]; then
  LAUNCH_DIR="${BIOS_DIR}"
elif [ -f "${SHARE_DIR}/${STATIC_BIN}" ]; then
  LAUNCH_DIR="${SHARE_DIR}"
else
  echo "ERROR: PICO-8 binary (${STATIC_BIN}) not found!"
  echo ""
  echo "Please purchase PICO-8 from https://www.lexaloffle.com/pico-8.php"
  echo "Download the Raspberry Pi edition and extract to:"
  echo "  - ${GAME_DIR}"
  echo ""
  echo "Alternatively, use the fake08 libretro core (free and open source)."
  exit 127
fi

# Share SDL controller DB
mkdir -p "${GAME_DIR}"
if [ -f "/usr/config/SDL-GameControllerDB/gamecontrollerdb.txt" ]; then
  cp -f /usr/config/SDL-GameControllerDB/gamecontrollerdb.txt "${GAME_DIR}/sdl_controllers.txt"
fi

chmod 0755 "${LAUNCH_DIR}/${STATIC_BIN}" 2>/dev/null

# Run PICO-8
"${LAUNCH_DIR}/${STATIC_BIN}" -home -root_path "${GAME_DIR}" -joystick 0 ${OPTIONS} "${CART}"
RC=$?

exit $RC
