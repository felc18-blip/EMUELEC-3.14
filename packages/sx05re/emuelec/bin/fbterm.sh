#!/usr/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

. /etc/profile

EE_DEVICE=$(cat /ee_arch)

ee_console enable

if [[ "${1}" == *"launch_terminal_(kb).sh"* ]]; then
        ee_console disable
    if [ "${EE_DEVICE}" == "OdroidGoAdvance" ] || [ "${EE_DEVICE}" == "GameForce" ]; then
        #kmscon
		kmscon --font-size 8 --login /usr/bin/login -- -p -f root 
    else
		tmpsh=/tmp/tmp.$$.sh
		echo "/usr/bin/login -p -f root" > ${tmpsh}
		chmod +x ${tmpsh}
		fbterm "${tmpsh}" -s 24 < /dev/tty1
		rm ${tmpsh}
    fi
elif [[ "${1}" == *"file_manager.sh"* ]]; then
        if [ "${EE_DEVICE}" == "OdroidGoAdvance" ] || [ "${EE_DEVICE}" == "GameForce" ]; then
            bash "${1}"
        else
            fbterm "${1}" -s 24 < /dev/tty1
        fi
elif [[ "${1}" == *"black_retro_scraper.sh"* ]]; then
        # Scripts dialog TUI (menu interativo com dialog) precisam rodar dentro
        # do fbterm pra renderizar no framebuffer. gptokeyb habilita controle.
        if [ "${EE_DEVICE}" == "OdroidGoAdvance" ] || [ "${EE_DEVICE}" == "GameForce" ]; then
            bash "${1}"
        else
            # Garante que não tem gptokeyb antigo rodando
            pkill -9 -f "gptokeyb -c /emuelec/configs/gptokeyb/351Files" 2>/dev/null
            sleep 0.3
            # Inicia gptokeyb em background
            if [[ -x /usr/bin/gptokeyb ]] && [[ -f /emuelec/configs/gptokeyb/351Files.gptk ]]; then
                /usr/bin/gptokeyb -c "/emuelec/configs/gptokeyb/351Files.gptk" &
                GPTOKEYB_PID=$!
            fi
            fbterm "${1}" -s 24 -n LiberationMono-Bold < /dev/tty1
            # Cleanup
            [[ -n "${GPTOKEYB_PID:-}" ]] && kill "${GPTOKEYB_PID}" 2>/dev/null
        fi
else
		case ${1} in
		"mplayer_video")
            bash playvideo.sh "${2}" "${3}" < /dev/tty0
		;;
		*)
            bash "${1}" > /dev/tty0
        ;;
		esac
fi 

ee_console disable
