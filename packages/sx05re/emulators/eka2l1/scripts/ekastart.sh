#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present worstcase_scenario (https://github.com/worstcase-scenario)

. /etc/profile

# ---------------------------------------------------------------------
# Paths / defaults
# ---------------------------------------------------------------------
EKA_EXE="/usr/bin/eka2l1/eka2l1_sdl2"
EKA_CONFIG_DIR="/storage/.config/eka2l1"
EKA_DATA_DIR="${EKA_CONFIG_DIR}/data"
EKA_DRIVES_DIR="${EKA_DATA_DIR}/drives"
EKA_E_DIR="${EKA_DRIVES_DIR}/e"
EKA_GPTK="/storage/.config/emuelec/configs/eka2l1/gptk/eka.gptk"
EKA_LOG="/emuelec/logs/eka2l1.log"

EKA_DEVICE_NGAGE1="${EKA_DEVICE_NGAGE1:-NEM-4}"
EKA_DEVICE_NGAGE1_ALT="${EKA_DEVICE_NGAGE1_ALT:-RH-29}"
EKA_DEVICE_NGAGE2="${EKA_DEVICE_NGAGE2:-RM-409}"

ROMFILE="$1"
LAUNCH_MODE="games"
APP_RUN=""
DEVICE_CODE="${EKA_DEVICE_NGAGE2}"
CLASSIC_NGAGE=0
CLEANUP_DONE=0

mkdir -p "$(dirname "${EKA_LOG}")"
echo "EmuELEC eka2l1 Log" > "${EKA_LOG}"

log() { echo "$*" >> "${EKA_LOG}"; }

device_installed() {
  local dev="$1"
  [ -z "${dev}" ] && return 1
  "${EKA_EXE}" --listdevices 2>/dev/null | grep -Fq "(${dev})"
}

select_ngage1_device() {
  if device_installed "${EKA_DEVICE_NGAGE1}"; then
    echo "${EKA_DEVICE_NGAGE1}"
  elif device_installed "${EKA_DEVICE_NGAGE1_ALT}"; then
    echo "${EKA_DEVICE_NGAGE1_ALT}"
  else
    echo "${EKA_DEVICE_NGAGE1}"
  fi
}

# ---------------------------------------------------------------------
# N-Gage 1 app name lookup table
# Key: lowercase game folder name (without .ngage)
# Value: exact --run name for eka2l1
# ---------------------------------------------------------------------
get_run_name() {
  local key
  key="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  case "${key}" in
    "ashen")                                    echo "Ashen" ;;
    "asphalt: urban gt 2"|"asphalt urban gt 2") echo "Asphalt 2" ;;
    "asphalt: urban gt"|"asphalt urban gt")     echo "Asphalt" ;;
    "atari masterpieces vol. 1"|"atari masterpieces vol 1") echo "Atari MP Vol I" ;;
    "atari masterpieces vol. ii"|"atari masterpieces vol ii") echo "Atari MP Vol II" ;;
    "bomberman")                                echo "Bomberman" ;;
    "call of duty")                             echo "CallofDuty" ;;
    "catan")                                    echo "Catan" ;;
    "civilization")                             echo "Civilization" ;;
    "colin mcrae rally 2005")                   echo "colin mcrae rally 2005" ;;
    "crash nitro kart")                         echo "CrashNitroKart" ;;
    "fifa football 2005"|"fifa 2005")           echo "FIFA 2005" ;;
    "fifa soccer 2004"|"fifa 2004")             echo "FIFA 2004" ;;
    "glimmerati")                               echo "Glimmerati" ;;
    "high seize")                               echo "High Seize" ;;
    "mlb slam!"|"mlb slam")                     echo "MLB Slam!" ;;
    "marcel desailly pro soccer")               echo "MarcelDesaillyProSoccer" ;;
    "mile high pinball")                        echo "Mile High" ;;
    "motogp")                                   echo "MotoGP" ;;
    "ncaa football 2004")                       echo "NCAA®" ;;
    "one")                                      echo "ONE" ;;
    "operation shadow")                         echo "Operation Shadow" ;;
    "pandemonium!")                             echo "Pandemonium" ;;
    "pathway to glory")                         echo "Pathway to Glory" ;;
    "pathway to glory: ikusa islands"|"ikusa islands") echo "Ikusa Islands" ;;
    "payload")                                  echo "Payload" ;;
    "pocket kingdom: own the world"|"pocket kingdom") echo "PKingdom" ;;
    "puyo pop")                                 echo "Puyo Pop" ;;
    "puzzle bobble vs")                         echo "PuzzleBobbleVS" ;;
    "rayman 3")                                 echo "Rayman 3" ;;
    "red faction")                              echo "RedFaction" ;;
    "requiem of hell")                          echo "Requiem of Hell" ;;
    "rifts: promise of power"|"rifts")          echo "RIFTS" ;;
    "ssx: out of bounds"|"ssx out of bounds"|"ssx") echo "SSX" ;;
    "sega rally championship")                  echo "SegaRally" ;;
    "snakes")                                   echo "Snakes" ;;
    "sonicn")                                   echo "SonicN" ;;
    "spider-man 2"|"spiderman 2")               echo "SM 2" ;;
    "super monkey ball")                        echo "supermonkeyball" ;;
    "system rush")                              echo "System Rush" ;;
    "the elder scrolls travels: shadowkey"|"shadowkey") echo "Elder Scrolls" ;;
    "the king of fighters: extreme"|"kof extreme") echo "KOF EXTREME" ;;
    "the roots: gates of chaos"|"the roots")    echo "The Roots" ;;
    "the sims: bustin' out"|"the sims bustin out") echo "The Sims Bustin' Out" ;;
    "tiger woods pga tour 2004")                echo "TW 2004" ;;
    "tom clancy's ghost recon: jungle storm"|"ghost recon") echo "GhostRecon" ;;
    "tom clancy's splinter cell: chaos theory") echo "SplinterCell" ;;
    "tom clancy's splinter cell: team stealth action"|"splinter cell") echo "Splinter Cell" ;;
    "tomb raider: starring lara croft"|"tomb raider") echo "Tomb Raider" ;;
    "tony hawk's pro skater")                   echo "Tony Hawk's Pro Skater" ;;
    "virtua cop")                               echo "Virtua Cop" ;;
    "virtua tennis")                            echo "virtuatennis" ;;
    "wwe: aftershock"|"wwe aftershock"|"wwe")   echo "WWE" ;;
    "warhammer 40,000: glory in death"|"warhammer 40000") echo "WH40K" ;;
    "worms: world party"|"worms world party")   echo "WWP" ;;
    "x-men legends ii: rise of apocalypse"|"x-men legends ii") echo "XMLII" ;;
    "x-men legends")                            echo "XMen™" ;;
    "xanadu next")                              echo "XanaduNEXT" ;;
    *) echo "" ;;
  esac
}

CLASSIC_APP_DST=""
CLASSIC_APP_SRC=""

save_classic_state() {
  [ -z "${CLASSIC_APP_DST}" ] && return
  [ ! -d "${CLASSIC_APP_DST}" ] && return
  [ -z "${CLASSIC_APP_SRC}" ] && return

  log "Syncing saves back to: ${CLASSIC_APP_SRC}"

  find "${CLASSIC_APP_DST}" -type f | while read -r DST_FILE; do
    REL="${DST_FILE#${CLASSIC_APP_DST}/}"
    SRC_FILE="${CLASSIC_APP_SRC}/${REL}"
    if [ ! -f "${SRC_FILE}" ] || [ "${DST_FILE}" -nt "${SRC_FILE}" ]; then
      mkdir -p "$(dirname "${SRC_FILE}")"
      cp -a "${DST_FILE}" "${SRC_FILE}"
      log "  Saved: ${REL}"
    fi
  done
}

cleanup() {
  [ "${CLEANUP_DONE}" = "1" ] && return
  CLEANUP_DONE=1

  save_classic_state

  if [ -n "${CLASSIC_APP_DST}" ] && [ -d "${CLASSIC_APP_DST}" ]; then
    log "Removing ${CLASSIC_APP_DST} from e:/system/apps/"
    rm -rf "${CLASSIC_APP_DST}"
  fi

  killall -9 gptokeyb 2>/dev/null
}
trap cleanup EXIT INT TERM HUP

# ---------------------------------------------------------------------
# Sanity check
# ---------------------------------------------------------------------
if [ ! -d "${EKA_DATA_DIR}" ]; then
  log "ERROR: eka2l1 not set up. Please run EKA_INSTALL first."
  exit 1
fi

mkdir -p "${EKA_DRIVES_DIR}" "${EKA_E_DIR}"

# ---------------------------------------------------------------------
# Detect launch mode
# ---------------------------------------------------------------------
if [ -n "${ROMFILE}" ]; then
  if [ -f "${ROMFILE}" ]; then
    case "${ROMFILE##*.}" in
      uid|UID)
        APP_UID="$(tr -d '\r\n[:space:]' < "${ROMFILE}")"
        if [ -n "${APP_UID}" ]; then
          case "${APP_UID}" in 0x*|0X*) ;; *) APP_UID="0x${APP_UID}" ;; esac
          LAUNCH_MODE="uid"
          DEVICE_CODE="$(select_ngage1_device)"
          log "UID launcher: ${APP_UID}"
          log "UID device selected: ${DEVICE_CODE}"
        fi
        ;;
    esac
  elif [ -d "${ROMFILE}" ]; then
    case "${ROMFILE}" in
      *.ngage|*.NGAGE)
        CLASSIC_NGAGE=1
        LAUNCH_MODE="classic"
        DEVICE_CODE="$(select_ngage1_device)"
        log "Classic N-Gage device selected: ${DEVICE_CODE}"

        GAME_FOLDER="$(basename "${ROMFILE}")"
        GAME_ID="${GAME_FOLDER%.ngage}"
        GAME_ID="${GAME_ID%.NGAGE}"

        SIDECAR="${ROMFILE%/}.name"
        if [ -f "${SIDECAR}" ]; then
          APP_RUN="$(tr -d '\r\n' < "${SIDECAR}")"
          log "App name from sidecar: ${APP_RUN}"
        else
          APP_RUN="$(get_run_name "${GAME_ID}")"
          if [ -z "${APP_RUN}" ]; then
            APP_RUN="$(echo "${GAME_ID}" | sed 's/\b\(.\)/\u\1/g')"
            log "App name from folder (fallback): ${APP_RUN}"
          else
            log "App name from lookup table: ${APP_RUN}"
          fi
        fi

        APP_FOLDER="$(ls "${ROMFILE}/system/apps/" 2>/dev/null | head -1)"
        if [ -n "${APP_FOLDER}" ]; then
          SRC="${ROMFILE}/system/apps/${APP_FOLDER}"
          DST="${EKA_E_DIR}/system/apps/${APP_FOLDER}"
          log "Installing ${APP_FOLDER} into e:/system/apps/"
          mkdir -p "${EKA_E_DIR}/system/apps"
          rm -rf "${DST}"
          cp -a "${SRC}" "${DST}"
          CLASSIC_APP_DST="${DST}"
          CLASSIC_APP_SRC="${SRC}"
        else
          log "ERROR: No app folder found in ${ROMFILE}/system/apps/"
          exit 1
        fi
        ;;
    esac
  fi
fi

# ---------------------------------------------------------------------
# gptokeyb
# ---------------------------------------------------------------------
killall -9 gptokeyb 2>/dev/null
gptokeyb 1 eka2l1_sdl2 -c "${EKA_GPTK}" &
sleep 1

cd "${EKA_CONFIG_DIR}" || exit 1

# ---------------------------------------------------------------------
# Launch
# ---------------------------------------------------------------------
if [ "${LAUNCH_MODE}" = "uid" ]; then
  log "Launching UID ${APP_UID} on ${DEVICE_CODE}"
  CUBEB_BACKEND=alsa "${EKA_EXE}" --device "${DEVICE_CODE}" --app "${APP_UID}" >> "${EKA_LOG}" 2>&1

elif [ "${LAUNCH_MODE}" = "classic" ]; then
  log "Launching classic N-Gage: --run \"${APP_RUN}\" on ${DEVICE_CODE}"
  CUBEB_BACKEND=alsa "${EKA_EXE}" --device "${DEVICE_CODE}" --run "${APP_RUN}" >> "${EKA_LOG}" 2>&1

else
  log "Launching N-Gage 2.0 Games app on ${DEVICE_CODE}"
  CUBEB_BACKEND=alsa "${EKA_EXE}" --device "${DEVICE_CODE}" --app Games >> "${EKA_LOG}" 2>&1
fi