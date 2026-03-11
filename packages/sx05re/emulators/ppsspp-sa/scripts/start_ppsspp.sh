#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Modificado para o BlackRetro Elite - S905L

. /etc/profile

# Força todos os núcleos ao máximo (Essencial para o S905L)
for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > "$i"
done

SOURCE_DIR="/usr/config/ppsspp-sa"
CONF_DIR="/storage/.config/ppsspp-sa"
PPSSPP_INI="/PSP/SYSTEM/ppsspp.ini"

# Garante a pasta de configuração no storage
if [ ! -d "${CONF_DIR}" ]; then
    mkdir -p "/storage/.config"
    cp -rf ${SOURCE_DIR} ${CONF_DIR}
fi

# --- Configurações do Emulation Station ---
GAME=$(echo "${1}"| sed "s#^/.*/##")
FSKIP=$(get_setting frame_skip psp "${GAME}")
FPS=$(get_setting show_fps psp "${GAME}")
IRES=$(get_setting internal_resolution psp "${GAME}")
GRENDERER=$(get_setting graphics_backend psp "${GAME}")
SKIPB=$(get_setting skip_buffer_effects psp "${GAME}")
VSYNC=$(get_setting vsync psp "${GAME}")

# Frame Skip
if [ "${FSKIP}" = "auto" ]; then
    sed -i '/AutoFrameSkip =/c\AutoFrameSkip = True' ${CONF_DIR}/${PPSSPP_INI}
else
    sed -i "/^FrameSkip =/c\FrameSkip = ${FSKIP:-0}" ${CONF_DIR}/${PPSSPP_INI}
    sed -i '/^FrameSkipType =/c\FrameSkipType = 0' ${CONF_DIR}/${PPSSPP_INI}
    sed -i '/^AutoFrameSkip =/c\AutoFrameSkip = False' ${CONF_DIR}/${PPSSPP_INI}
fi

# Graphics Backend (0 = OpenGL, 3 = Vulkan)
if [ "${GRENDERER}" = "vulkan" ]; then
    sed -i '/^GraphicsBackend =/c\GraphicsBackend = 3 (VULKAN)' ${CONF_DIR}/${PPSSPP_INI}
else
    sed -i '/^GraphicsBackend =/c\GraphicsBackend = 0 (OPENGL)' ${CONF_DIR}/${PPSSPP_INI}
fi

# Internal Resolution
sed -i "/^InternalResolution/c\InternalResolution = ${IRES:-1}" ${CONF_DIR}/${PPSSPP_INI}

# Show FPS (2 = Show FPS)
if [ "${FPS}" = "1" ]; then
    sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 2' ${CONF_DIR}/${PPSSPP_INI}
else
    sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 0' ${CONF_DIR}/${PPSSPP_INI}
fi

# Skip Buffer Effects
if [ "${SKIPB}" = "1" ]; then
    sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = True' ${CONF_DIR}/${PPSSPP_INI}
else
    sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = False' ${CONF_DIR}/${PPSSPP_INI}
fi

# VSYNC
if [ "${VSYNC}" = "1" ]; then
    sed -i '/^VSyncInterval =/c\VSyncInterval = True' ${CONF_DIR}/${PPSSPP_INI}
else
    sed -i '/^VSyncInterval =/c\VSyncInterval = False' ${CONF_DIR}/${PPSSPP_INI}
fi

# Execução do Emulador
ARG=${1//[\\]/}
set_kill set "-9 ppsspp-sa"

ppsspp-sa --pause-menu-exit "${ARG}"