#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

. /etc/profile

SOURCE_DIR="/usr/config/ppsspp-sa"
CONF_DIR="/storage/.config/ppsspp-sa"
PPSSPP_INI="/PSP/SYSTEM/ppsspp.ini"

# copia config inicial
if [ ! -d "${CONF_DIR}" ]; then
  cp -rf ${SOURCE_DIR} ${CONF_DIR}
fi

# define HOME do PPSSPP (IMPORTANTE)
export PPSSPP_HOME=${CONF_DIR}

# Set the cores to use
CORES=$(get_setting "cores" "${PLATFORM}" "${ROMNAME##*/}")
if [ "${CORES}" = "little" ]; then
  EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]; then
  EMUPERF="${FAST_CORES}"
else
  unset EMUPERF
fi

# Emulation Station Features
GAME=$(echo "${1}" | sed "s#^/.*/##")
FSKIP=$(get_setting frame_skip psp "${GAME}")
FPS=$(get_setting show_fps psp "${GAME}")
IRES=$(get_setting internal_resolution psp "${GAME}")
GRENDERER=$(get_setting graphics_backend psp "${GAME}")
SKIPB=$(get_setting skip_buffer_effects psp "${GAME}")
VSYNC=$(get_setting vsync psp "${GAME}")

INI="${CONF_DIR}${PPSSPP_INI}"

# Frame Skip
case "${FSKIP}" in
  0|1|2|3)
    sed -i "/^FrameSkip =/c\FrameSkip = ${FSKIP}" ${INI}
    sed -i "/^FrameSkipType =/c\FrameSkipType = 0" ${INI}
    sed -i "/^AutoFrameSkip =/c\AutoFrameSkip = False" ${INI}
    ;;
  auto)
    sed -i "/^AutoFrameSkip =/c\AutoFrameSkip = True" ${INI}
    ;;
esac

# Graphics Backend
sed -i '/^GraphicsBackend =/c\GraphicsBackend = 0 (OPENGL)' ${INI}
[ "${GRENDERER}" = "vulkan" ] && \
  sed -i '/^GraphicsBackend =/c\GraphicsBackend = 3 (VULKAN)' ${INI}

# Internal Resolution
[ -n "${IRES}" ] && sed -i "/^InternalResolution/c\InternalResolution = ${IRES}" ${INI}

# Show FPS
if [ "${FPS}" = "1" ]; then
  sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 2' ${INI}
else
  sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 0' ${INI}
fi

# Skip Buffer Effects
[ "${SKIPB}" = "1" ] && \
  sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = True' ${INI} || \
  sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = False' ${INI}

# VSYNC
[ "${VSYNC}" = "1" ] && \
  sed -i '/^VSyncInterval =/c\VSyncInterval = True' ${INI} || \
  sed -i '/^VSyncInterval =/c\VSyncInterval = False' ${INI}

ARG=${1//[\\]/}

set_kill set "-9 PPSSPPSA"

# EXEC CORRETO (IMPORTANTE)
${EMUPERF} /usr/bin/PPSSPPSA --pause-menu-exit "${ARG}"