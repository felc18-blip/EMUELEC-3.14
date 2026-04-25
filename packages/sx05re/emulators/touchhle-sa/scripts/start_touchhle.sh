#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS Elite Edition - touchHLE launcher (emuelec style)

. /etc/profile

set_kill_keys "touchHLE"

# touchHLE mmaps a 4 GiB host buffer to simulate the ARMv7 address space.
# Default vm.overcommit_memory=0 (heuristic) rejects this on devices with
# <4 GiB RAM. Switch to 1 (always overcommit) — only commits pages the
# guest actually touches.
sysctl -w vm.overcommit_memory=1 >/dev/null 2>&1

# sdl2-compat → SDL3 on NextOS Amlogic-old only exposes "mali" video
# driver (no fbdev/kmsdrm/x11). Force it explicitly so SDL doesn't probe
# fbdev and bail with "fbdev not available".
export SDL_VIDEODRIVER=mali

# ---------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------
SOURCE_DIR="/usr/config/emuelec/configs/touchHLE"
CONFIG_DIR="/storage/.config/emuelec/configs/touchHLE"
TOUCHHLE_CONF="touchHLE_options.txt"
ROMS_DIR="/storage/roms/ios"
EMUELECLOG="/emuelec/logs/touchhle.log"

mkdir -p "$(dirname "${EMUELECLOG}")"
echo "EmuELEC touchHLE Log" > "${EMUELECLOG}"

mkdir -p "${CONFIG_DIR}"
mkdir -p "${ROMS_DIR}"

# Seed user config from the package on first run.
if [ ! -f "${CONFIG_DIR}/${TOUCHHLE_CONF}" ] && [ -f "${SOURCE_DIR}/${TOUCHHLE_CONF}" ]; then
  cp -f "${SOURCE_DIR}/${TOUCHHLE_CONF}" "${CONFIG_DIR}/"
fi

# Generate a 1x1 placeholder wallpaper if none exists (touchHLE requires
# at least one wallpaper file in user data dir to draw the app picker).
if ! compgen -G "${CONFIG_DIR}/touchHLE_wallpaper.*" > /dev/null; then
  printf \
    '\x89PNG\r\n\x1a\n'\
    '\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde'\
    '\x00\x00\x00\x0cIDAT\x08\xd7c\x60\x60\x60\x00\x00\x00\x04\x00\x01\xf6\x17\x38\x55'\
    '\x00\x00\x00\x00IEND\xaeB`\x82' \
    > "${CONFIG_DIR}/touchHLE_wallpaper.png"
fi

# touchHLE looks for apps in <user_data>/touchHLE_apps; symlink that to
# the ES rom dir so users only manage one location.
ln -snf "${ROMS_DIR}" "${CONFIG_DIR}/touchHLE_apps"

# ---------------------------------------------------------------------
# emuelec settings (per-platform / per-game overrides)
# ---------------------------------------------------------------------
GAME=$(echo "${1}" | sed "s#^/.*/##")
PLATFORM=$(echo "${2}" | sed "s#^/.*/##")
[ -z "${PLATFORM}" ] && PLATFORM="ios"

DEVICE=$(get_ee_setting touchhle_device "${PLATFORM}" "${GAME}")
UPSCALE=$(get_ee_setting touchhle_upscale "${PLATFORM}" "${GAME}")
CORES=$(get_ee_setting cores "${PLATFORM}" "${GAME}")

# Device family: "iphone" (default) or "ipad"
case "${DEVICE}" in
  ipad) DEVICE="ipad" ;;
  *)    DEVICE="iphone" ;;
esac

# Upscale 1..4 (nearest integer scale of the framebuffer)
if [[ "${UPSCALE}" =~ ^[1-4]$ ]]; then
  :
else
  UPSCALE=1
fi

# CPU pinning (big/little/all) — same convention as other NextOS emus
case "${CORES}" in
  little) EMUPERF="${SLOW_CORES}" ;;
  big)    EMUPERF="${FAST_CORES}" ;;
  *)      unset EMUPERF ;;
esac

# ---------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------
{
  echo "GAME:     ${GAME}"
  echo "PLATFORM: ${PLATFORM}"
  echo "CONFIG:   ${CONFIG_DIR}"
  echo "DEVICE:   ${DEVICE}"
  echo "UPSCALE:  ${UPSCALE}"
  echo "CORES:    ${EMUPERF}"
  echo "CMD:      /usr/bin/touchHLE --fullscreen --scale-hack=${UPSCALE} --device-family=${DEVICE} \"${1}\""
} >> "${EMUELECLOG}"

cd "${CONFIG_DIR}" || exit 1

${EMUPERF} /usr/bin/touchHLE \
  --fullscreen \
  --scale-hack="${UPSCALE}" \
  --device-family="${DEVICE}" \
  "${1}" >> "${EMUELECLOG}" 2>&1
