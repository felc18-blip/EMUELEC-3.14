#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

. /etc/profile

SOURCE_DIR="/usr/config/ppsspp-sa"
CONF_DIR="/storage/.config/ppsspp-sa"
PPSSPP_INI="/PSP/SYSTEM/ppsspp.ini"

ROMPPSSPPFOLDER="/storage/roms/savestates/PPSSPPSA/PSP"
PPSSPPFOLDER="${CONF_DIR}/PSP"

# garantir config inicial
if [ ! -d "${CONF_DIR}" ]; then
    mkdir -p "/storage/.config"
    cp -rf ${SOURCE_DIR} ${CONF_DIR}
fi

# mover saves para pasta global
for dir in Cheats PPSSPP_STATE SAVEDATA TEXTURES; do
    mkdir -p "${ROMPPSSPPFOLDER}"

    if [ ! -L ${PPSSPPFOLDER}/${dir} ]; then
        cp -rf ${PPSSPPFOLDER}/${dir}/. ${ROMPPSSPPFOLDER}/${dir}/ 2>/dev/null
        rm -rf ${PPSSPPFOLDER}/${dir}
        ln -sf ${ROMPPSSPPFOLDER}/${dir} ${PPSSPPFOLDER}/${dir}
    fi
done

# garantir cheat.db
if [ ! -s "${ROMPPSSPPFOLDER}/Cheats/cheat.db" ]; then
    mkdir -p "${ROMPPSSPPFOLDER}/Cheats"
    cp -rf ${SOURCE_DIR}/PSP/SYSTEM/Cheats/. "${ROMPPSSPPFOLDER}/Cheats/" 2>/dev/null

    CHEAT_DB_VERSION="06d4d6148b66109005f7d51c37e8344f0bc042cc"
    curl -sLo "${ROMPPSSPPFOLDER}/Cheats/cheat.db" -f \
    "https://raw.githubusercontent.com/Saramagrean/CWCheat-Database-Plus-/${CHEAT_DB_VERSION}/cheat.db" || true
fi

# -------- EmulationStation configs --------

GAME=$(echo "${1}" | sed "s#^/.*/##")

FSKIP=$(get_setting frame_skip psp "${GAME}")
FPS=$(get_setting show_fps psp "${GAME}")
IRES=$(get_setting internal_resolution psp "${GAME}")
GRENDERER=$(get_setting graphics_backend psp "${GAME}")
SKIPB=$(get_setting skip_buffer_effects psp "${GAME}")
VSYNC=$(get_setting vsync psp "${GAME}")

# Frame skip
if [ "${FSKIP}" = "auto" ]; then
    sed -i '/AutoFrameSkip =/c\AutoFrameSkip = True' ${CONF_DIR}${PPSSPP_INI}
else
    sed -i "/^FrameSkip =/c\FrameSkip = ${FSKIP:-0}" ${CONF_DIR}${PPSSPP_INI}
    sed -i '/^FrameSkipType =/c\FrameSkipType = 0' ${CONF_DIR}${PPSSPP_INI}
    sed -i '/^AutoFrameSkip =/c\AutoFrameSkip = False' ${CONF_DIR}${PPSSPP_INI}
fi

# backend gráfico
if [ "${GRENDERER}" = "vulkan" ]; then
    sed -i '/^GraphicsBackend =/c\GraphicsBackend = 3 (VULKAN)' ${CONF_DIR}${PPSSPP_INI}
else
    sed -i '/^GraphicsBackend =/c\GraphicsBackend = 0 (OPENGL)' ${CONF_DIR}${PPSSPP_INI}
fi

# resolução interna
sed -i "/^InternalResolution/c\InternalResolution = ${IRES:-1}" ${CONF_DIR}${PPSSPP_INI}

# mostrar FPS
if [ "${FPS}" = "1" ]; then
    sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 2' ${CONF_DIR}${PPSSPP_INI}
else
    sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 0' ${CONF_DIR}${PPSSPP_INI}
fi

# skip buffer
if [ "${SKIPB}" = "1" ]; then
    sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = True' ${CONF_DIR}${PPSSPP_INI}
else
    sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = False' ${CONF_DIR}${PPSSPP_INI}
fi

# vsync
if [ "${VSYNC}" = "1" ]; then
    sed -i '/^VSyncInterval =/c\VSyncInterval = True' ${CONF_DIR}${PPSSPP_INI}
else
    sed -i '/^VSyncInterval =/c\VSyncInterval = False' ${CONF_DIR}${PPSSPP_INI}
fi

# executar
ARG=${1//[\\]/}

export SDL_AUDIODRIVER=alsa
set_kill set "-9 ppsspp-sa"

ppsspp-sa --fullscreen --pause-menu-exit "${ARG}"