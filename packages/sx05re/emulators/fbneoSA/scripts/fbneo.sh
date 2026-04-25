#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

add_player_hat() 
{
    local pl=${1}
    local pf="/storage/.local/share/fbneo/config/p${pl}defaults.ini"

    if [ ! -f "${pf}" ]; then
      echo "version 0x100003" > ${pf}
      echo "macro \"P${pl} Up\" switch 0x4012" >> ${pf}
      echo "macro \"P${pl} Down\" switch 0x4013" >> ${pf}
      echo "macro \"P${pl} Left\" switch 0x4010" >> ${pf}
      echo "macro \"P${pl} Right\" switch 0x4011" >> ${pf}
    fi
}

mkdir -p /emuelec/configs/fbneo/config
mkdir -p /storage/.local/share

if [ -d "/storage/.local/share/fbneo/" ]; then
    mv -f /storage/.local/share/fbneo/* /emuelec/configs/fbneo
    rm -rf /storage/.local/share/fbneo
    ln -sf /emuelec/configs/fbneo /storage/.local/share/fbneo
fi

if [ ! -L "/storage/.local/share/fbneo" ]; then
    ln -sf /emuelec/configs/fbneo /storage/.local/share/fbneo
fi

add_player_hat 1
add_player_hat 2
add_player_hat 3
add_player_hat 4

# TODO: Allow settings from ES 
#case "$@" in
#EXTRAOPTS=

if [ "${2}" == "NCD" ]; then
    echo . > /dev/null
    #EXTRAOPTS=CDOPTS?
fi

ROM=$(basename -- "${1}")
ROM="${ROM%.*}"
DIR=$(dirname ${1})

sed -i "s|szAppRomPaths\[0\].*|szAppRomPaths\[0\] ${DIR}/|" /emuelec/configs/fbneo/config/fbneo.ini

export LIBGL_NOBANNER=1
export LIBGL_SILENTSTUB=1

fbfix $( emuelec-utils getmainfb )

# NextOS: gptokeyb monitora Select+Start e mata fbneo (atalho de saida).
# fbneo -joy le SDL_JOYBUTTONDOWN direto, gptkb mapeia o minimo p/ nao
# conflitar com gameplay.
GPTK_CFG=/emuelec/configs/gptokeyb/fbneo.gptk
if [ -f "$GPTK_CFG" ] && [ -x /usr/bin/gptokeyb ]; then
  /usr/bin/gptokeyb -1 fbneo -c "$GPTK_CFG" &
  GPTK_PID=$!
  trap "kill $GPTK_PID 2>/dev/null" EXIT
fi

fbneo -joy -fullscreen "${ROM}" ${EXTRAOPTS} >> /emuelec/logs/emuelec.log 2>&1
[ -n "$GPTK_PID" ] && kill "$GPTK_PID" 2>/dev/null
