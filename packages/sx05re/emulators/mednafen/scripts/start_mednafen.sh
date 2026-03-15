#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS

. /etc/profile

killall -9 mednafen 2>/dev/null

export MEDNAFEN_HOME=/storage/.mednafen
export MEDNAFEN_CONFIG=/usr/config/mednafen/mednafen.template

mkdir -p "$MEDNAFEN_HOME"

if [ ! -f "$MEDNAFEN_HOME/mednafen.cfg" ]; then
    /usr/bin/bash /usr/bin/mednafen_gen_config.sh
fi

# EmulationStation variables
GAME=$(basename "${1}")
CORE=$(basename "${2}")
PLATFORM=$(basename "${3}")

STRETCH=$(get_ee_setting stretch "${PLATFORM}" "${GAME}")
SHADER=$(get_ee_setting shader "${PLATFORM}" "${GAME}")

CORES=$(get_ee_setting cores "${PLATFORM}" "${GAME}")

if [ "${CORES}" = "little" ]; then
    EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]; then
    EMUPERF="${FAST_CORES}"
else
    unset EMUPERF
fi

sed -i "s/filesys.path_sav .*/filesys.path_sav \/storage\/roms\/${PLATFORM}/g" "$MEDNAFEN_HOME/mednafen.cfg"
sed -i "s/filesys.path_savbackup.*/filesys.path_savbackup \/storage\/roms\/${PLATFORM}/g" "$MEDNAFEN_HOME/mednafen.cfg"
sed -i "s/filesys.path_state.*/filesys.path_state \/storage\/roms\/savestates\/${PLATFORM}/g" "$MEDNAFEN_HOME/mednafen.cfg"

FEATURES_CMDLINE=""

if [[ "${CORE}" =~ pce(_fast)? ]]; then

    if [ "$(get_ee_setting nospritelimit ${PLATFORM} "${GAME}")" = "1" ]; then
        FEATURES_CMDLINE+=" -${CORE}.nospritelimit 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.nospritelimit 0"
    fi

    if [ "$(get_ee_setting forcesgx ${PLATFORM} "${GAME}")" = "1" ]; then
        FEATURES_CMDLINE+=" -${CORE}.forcesgx 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.forcesgx 0"
    fi

    if [ "${CORE}" = "pce_fast" ]; then

        OCM=$(get_ee_setting ocmultiplier ${PLATFORM} "${GAME}")
        if [ "${OCM}" -gt 1 ]; then
            FEATURES_CMDLINE+=" -${CORE}.ocmultiplier ${OCM}"
        else
            FEATURES_CMDLINE+=" -${CORE}.ocmultiplier 1"
        fi

        CDS=$(get_ee_setting cdspeed ${PLATFORM} "${GAME}")
        if [ "${CDS}" -gt 1 ]; then
            FEATURES_CMDLINE+=" -${CORE}.cdspeed ${CDS}"
        else
            FEATURES_CMDLINE+=" -${CORE}.cdspeed 1"
        fi
    fi

fi

ARG=${1//[\\]/}

# ambiente gráfico Mali
export SDL_AUDIODRIVER=dummy
export SDL_VIDEODRIVER=mali

export LD_PRELOAD=/usr/lib/libMali.so
export SDL_VIDEO_EGL_DRIVER=/usr/lib/libEGL.so
export SDL_VIDEO_GL_DRIVER=/usr/lib/libGL.so

${EMUPERF} /usr/bin/mednafen \
-force_module ${CORE} \
-${CORE}.stretch ${STRETCH:="aspect"} \
-${CORE}.shader ${SHADER:="ipsharper"} \
${FEATURES_CMDLINE} "${ARG}"