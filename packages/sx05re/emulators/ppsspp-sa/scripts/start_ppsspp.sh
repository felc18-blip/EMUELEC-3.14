#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

. /etc/profile

SOURCE_DIR="/usr/config/ppsspp-sa"
CONF_DIR="/storage/.config/ppsspp-sa"
ROMSPPSSPPFOLDER=/storage/roms/savestates/ppsspp-sa/PSP
mkdir -p "${ROMSPPSSPPFOLDER}"

PPSSPP_INI="/PSP/SYSTEM/ppsspp.ini"

if [ ! -d "${CONF_DIR}" ]
then
  cp -rf ${SOURCE_DIR} ${CONF_DIR}
fi

# Garantir symlinks
for dir in Cheats PPSSPP_STATE SAVEDATA TEXTURES; do
    mkdir -p "${ROMSPPSSPPFOLDER}/${dir}"

    if [ ! -L ${CONF_DIR}/PSP/${dir} ]; then
        cp -rf ${CONF_DIR}/PSP/${dir}/. ${ROMSPPSSPPFOLDER}/${dir}/ 2>/dev/null
        rm -rf ${CONF_DIR}/PSP/${dir}
        ln -sf ${ROMSPPSSPPFOLDER}/${dir} ${CONF_DIR}/PSP/${dir}
    fi
done

# Garantir cheat.db
if [ ! -s "${ROMSPPSSPPFOLDER}/Cheats/cheat.db" ]; then
    mkdir -p "${ROMSPPSSPPFOLDER}/Cheats/"
    cp -rf ${SOURCE_DIR}/PSP/SYSTEM/Cheats/. "${ROMSPPSSPPFOLDER}/Cheats/" 2>/dev/null
fi

# Performance cores
CORES=$(get_ee_setting cores psp "${1##*/}")
if [ "${CORES}" = "little" ]; then
  EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]; then
  EMUPERF="${FAST_CORES}"
else
  unset EMUPERF
fi

ARG=${1//[\\]/}

export SDL_AUDIODRIVER=alsa

set_kill set "-9 ppsspp-sa"

${EMUPERF} ppsspp-sa --fullscreen --pause-menu-exit "${ARG}"