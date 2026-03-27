#!/bin/bash
. /etc/profile

# 1. Resolução
case "$(oga_ver)" in
    "OGA"*) SW="480"; SH="320" ;;
    "OGS")  SW="854"; SH="480" ;;
    "GF")   SW="640"; SH="480" ;;
    *)      read -r SW SH <<< "$(echo $(get_resolution))" ;;
esac
[[ -z "$SW" ]] && SW="1280" ; [[ -z "$SH" ]] && SH="720"

# File locations
SHARE="/usr/local/share/mupen64plus"
GAMEDATA="/storage/.config/mupen64plus"
M64PCONF="${GAMEDATA}/mupen64plus.cfg"
CUSTOMINP="${GAMEDATA}/custominput.ini"
TMP="/tmp/mupen64plus"

rm -rf ${TMP}
mkdir -p ${TMP}
mkdir -p ${GAMEDATA}

# 3. Prepara arquivo base no TMP
if [ -f "${SHARE}/default.ini" ]; then
    cp "${SHARE}/default.ini" "${TMP}/InputAutoCfg.ini"
else
    touch "${TMP}/InputAutoCfg.ini"
fi

# =========================================================================
# 4. TRADUTOR AUTOMÁTICO MULTIPLAYER (Agora à prova de espaços no meio)
# =========================================================================
SDL_DB="/storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt"
INJECTED_LIST="${TMP}/injected_pads.txt"
touch "$INJECTED_LIST"

# Detecta todos os joysticks conectados
CONNECTED_PADS=$(awk '/^N: Name="/ {name=$0; sub(/N: Name="/, "", name); sub(/"$/, "", name)} /^H: Handlers=.*js[0-9]+/ {print name}' /proc/bus/input/devices)

if [ -f "$SDL_DB" ] && [ -n "$CONNECTED_PADS" ]; then
    while IFS= read -r raw_name; do
        [[ -z "$raw_name" ]] && continue
        
        # A MÁGICA FINAL: Remove espaços do começo/fim e esmaga os espaços do meio!
        dev_name=$(echo "$raw_name" | sed 's/^ *//;s/ *$//' | tr -s ' ')
        
        grep -q -F "$dev_name" "$INJECTED_LIST" && continue
        
        SDL_LINE=$(grep -F ",${dev_name}," "$SDL_DB" | head -n1)
        
        if [ -n "$SDL_LINE" ]; then
            echo "==== TRADUZINDO CONTROLE DETECTADO: $dev_name ===="
            M_A=""; M_B=""; M_S=""; M_Z=""; M_L=""; M_R=""; M_X=""; M_Y=""
            M_CR=""; M_CL=""; M_CD=""; M_CU=""
            M_DPR=""; M_DPL=""; M_DPD=""; M_DPU=""

            IFS=',' read -ra PARTS <<< "$SDL_LINE"
            for part in "${PARTS[@]}"; do
                key="${part%%:*}"
                val="${part#*:}"
                
                m_val=""
                if [[ "$val" == b* ]]; then m_val="button(${val:1})"
                elif [[ "$val" == h0.1 ]]; then m_val="hat(0 Up)"
                elif [[ "$val" == h0.2 ]]; then m_val="hat(0 Right)"
                elif [[ "$val" == h0.4 ]]; then m_val="hat(0 Down)"
                elif [[ "$val" == h0.8 ]]; then m_val="hat(0 Left)"
                elif [[ "$val" == a* ]]; then m_val="axis(${val:1}+)"
                fi

                case "$key" in
                    a) M_A="$m_val" ;;
                    b|x) [ -z "$M_B" ] && M_B="$m_val" ;;
                    start) M_S="$m_val" ;;
                    leftshoulder) M_L="$m_val" ;;
                    rightshoulder) M_R="$m_val" ;;
                    lefttrigger) M_Z="$m_val" ;;
                    dpup) M_DPU="$m_val" ;;
                    dpdown) M_DPD="$m_val" ;;
                    dpleft) M_DPL="$m_val" ;;
                    dpright) M_DPR="$m_val" ;;
                    leftx) M_X="axis(${val:1}-,${val:1}+)" ;;
                    lefty) M_Y="axis(${val:1}-,${val:1}+)" ;;
                    rightx) M_CR="axis(${val:1}+)"; M_CL="axis(${val:1}-)" ;;
                    righty) M_CD="axis(${val:1}+)"; M_CU="axis(${val:1}-)" ;;
                esac
            done

            cat << EOT >> "${TMP}/InputAutoCfg.ini"

[$dev_name]
plugged = True
plugin = 2
mouse = False
DPad R = $M_DPR
DPad L = $M_DPL
DPad D = $M_DPD
DPad U = $M_DPU
Start = $M_S
Z Trig = $M_Z
B Button = $M_B
A Button = $M_A
R Trig = $M_R
L Trig = $M_L
C Button R = $M_CR
C Button L = $M_CL
C Button D = $M_CD
C Button U = $M_CU
X Axis = $M_X
Y Axis = $M_Y
EOT
            echo "$dev_name" >> "$INJECTED_LIST"
            echo "==== INJEÇÃO DE '$dev_name' CONCLUÍDA COM SUCESSO ===="
        else
            echo "AVISO: O controle '$dev_name' não tem mapeamento no SDL_DB."
        fi
    done <<< "$CONNECTED_PADS"
fi
# =========================================================================

# 5. Config do Core
[[ ! -f "${GAMEDATA}/mupen64plus.cfg" ]] && cp ${SHARE}/mupen64plus.cfg* ${GAMEDATA}/ 2>/dev/null
cp ${GAMEDATA}/mupen64plus.cfg ${TMP}/mupen64plus.cfg 2>/dev/null || echo "[Core]" > ${TMP}/mupen64plus.cfg

# 6. ROM
if [[ "$1" == *.zip ]]; then
    7za x -y "$1" -o${TMP} >/dev/null 2>&1
    ROM_P=$(find ${TMP} -maxdepth 1 \( -name "*.z64" -o -name "*.n64" -o -name "*.v64" -o -name "*.bin" \) | head -n1)
    ROM_NAME=$(basename "$ROM_P")
else
    cp "$1" ${TMP}/
    ROM_NAME=$(basename "$1")
fi

# 7. Execução e Setup Multiplayer (Versão Final Turbinada)
VPLUGIN="$2"
[[ -z "${VPLUGIN}" ]] && VPLUGIN="rice"

# Início dos parâmetros (Resolução e Multiplayer)
SET_PARAMS="--set Core[SharedDataPath]=${TMP}"
SET_PARAMS+=" --set Video-General[ScreenWidth]=${SW}"
SET_PARAMS+=" --set Video-General[ScreenHeight]=${SH}"
SET_PARAMS+=" --set Video-Rice[ResolutionWidth]=${SW}"
SET_PARAMS+=" --set Video-Rice[ResolutionHeight]=${SH}"
SET_PARAMS+=" --set Input-SDL-Control1[plugged]=True --set Input-SDL-Control1[device]=0"
SET_PARAMS+=" --set Input-SDL-Control2[plugged]=True --set Input-SDL-Control2[device]=1"
SET_PARAMS+=" --set Input-SDL-Control3[plugged]=True --set Input-SDL-Control3[device]=2"
SET_PARAMS+=" --set Input-SDL-Control4[plugged]=True --set Input-SDL-Control4[device]=3"

# Lógica Dinâmica de Vídeo (Para aceitar glide, parallel, etc.)
case ${VPLUGIN} in
    "rmg_parallel")
        SET_PARAMS+=" --gfx mupen64plus-video-parallel.so"
        RSP="parallel"
    ;;
    "gliden64")
        SET_PARAMS+=" --gfx mupen64plus-video-GLideN64.so"
    ;;
    "gl64mk2")
        SET_PARAMS+=" --gfx mupen64plus-video-glide64mk2.so"
    ;;
    "rice"|*)
        SET_PARAMS+=" --gfx mupen64plus-video-rice.so"
    ;;
esac

# Lógica Dinâmica de RSP
case "${RSP}" in
    "parallel")
        SET_PARAMS+=" --rsp mupen64plus-rsp-parallel.so"
    ;;
    "hle")
        SET_PARAMS+=" --rsp mupen64plus-rsp-hle.so"
    ;;
    *)
        SET_PARAMS+=" --rsp mupen64plus-rsp-cxd4.so"
    ;;
esac

# Plugins de Audio e Input (SDL)
SET_PARAMS+=" --audio mupen64plus-audio-sdl.so"
SET_PARAMS+=" --input mupen64plus-input-sdl.so"

# Comando Final de Execução
/usr/local/bin/mupen64plus --configdir ${TMP} --datadir ${TMP} --fullscreen --resolution "${SW}x${SH}" ${SET_PARAMS} "${TMP}/${ROM_NAME}"

# rm -rf ${TMP}/*
