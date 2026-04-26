#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present Langerz82 (https://github.com/Langerz82)

# Source predefined functions and variables
. /etc/profile

# DO NOT modify this file. 

# It seems some slow SDcards have a problem creating the symlink on time :/
CONFIG_FLASH="/flash/config.ini"
VIDEO_FILE="/storage/.config/EE_VIDEO_MODE"
VIDEO_MODE="/sys/class/display/mode"



# If the video-mode is contained in flash config.
DEFE=""

# FLASH CONFIG hdmimode takes priority 1.
if [ -z "${DEFE}" ]; then
  CFG_VAL=$(get_config_value "${CONFIG_FLASH}" "vout")
  if [[ ! -z "${CFG_VAL}" ]]; then
    DEFE="${CFG_VAL}"
  fi
fi

# Check for EE_VIDEO_MODE override 2nd.
if [[ -z "${DEFE}" && -f "${VIDEO_FILE}" ]]; then
  DEFE=$(cat ${VIDEO_FILE})
fi

# 3rd check ES for it's preferred resolution.
if [ -z "${DEFE}" ]; then
  DEFE=$(get_ee_setting ee_videomode)
  if [ "${DEFE}" == "Custom" ]; then
      DEFE=$(cat ${VIDEO_MODE})
  fi
fi

# 4th: NextOS — if nothing has been chosen by the user, take the EDID
# preferred mode reported by the TV (the entry marked with '*' in
# /sys/class/amhdmitx/amhdmitx0/disp_cap). Avoids booting at the kernel
# default (often 720p) when the panel actually supports 1080p+.
if [[ -z "${DEFE}" && -f /sys/class/amhdmitx/amhdmitx0/disp_cap ]]; then
  EDID_PREF=$(grep -m1 '\*' /sys/class/amhdmitx/amhdmitx0/disp_cap 2>/dev/null | tr -d '*' | tr -d '[:space:]')
  if [[ -n "${EDID_PREF}" ]]; then
    DEFE="${EDID_PREF}"
  fi
fi

# Set video mode, this has to be done before starting ES
# finally we correct the FB according to video mode
[[ ! -z "${DEFE}" ]] && [[ -f "${VIDEO_MODE}" ]] && setres.sh ${DEFE}

