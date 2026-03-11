#!/bin/bash

. /etc/profile

APP="/usr/bin/aethersx2-sa"
CFG="/storage/.config/aethersx2/inis/PCSX2.ini"

#Check if aethersx2 exists in .config
if [ ! -d "/storage/.config/aethersx2" ]; then
    mkdir -p "/storage/.config/aethersx2"
    cp -r "/usr/config/aethersx2" "/storage/.config/"
fi

#Make Aethersx2 bios folder
if [ ! -d "/storage/roms/bios/aethersx2" ]; then
    mkdir -p "/storage/roms/bios/aethersx2"
fi

#Create PS2 savestates folder
if [ ! -d "/storage/roms/savestates/ps2" ]; then
    mkdir -p "/storage/roms/savestates/ps2"
fi

#Set the cores to use
CORES=$(get_setting "cores" "${PLATFORM}" "${ROMNAME##*/}")
if [ "${CORES}" = "little" ]; then
  EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]; then
  EMUPERF="${FAST_CORES}"
else
  unset EMUPERF
fi

#Emulation Station Features
GAME=$(echo "${1}" | sed "s#^/.*/##")
ASPECT=$(get_setting aspect_ratio ps2 "${GAME}")
FILTER=$(get_setting bilinear_filtering ps2 "${GAME}")
FPS=$(get_setting show_fps ps2 "${GAME}")
RATE=$(get_setting ee_cycle_rate ps2 "${GAME}")
SKIP=$(get_setting ee_cycle_skip ps2 "${GAME}")
GRENDERER=$(get_setting graphics_backend ps2 "${GAME}")
IRES=$(get_setting internal_resolution ps2 "${GAME}")

#Aspect Ratio
if [ "$ASPECT" = "0" ]; then
  sed -i '/^AspectRatio =/c\AspectRatio = 4:3' "$CFG"
fi
if [ "$ASPECT" = "1" ]; then
  sed -i '/^AspectRatio =/c\AspectRatio = 16:9' "$CFG"
fi
if [ "$ASPECT" = "2" ]; then
  sed -i '/^AspectRatio =/c\AspectRatio = Stretch' "$CFG"
fi

#Bilinear Filtering
if [ -n "$FILTER" ]; then
  sed -i "/^filter =/c\filter = $FILTER" "$CFG"
fi

#Graphics Backend
if [ "$GRENDERER" = "0" ]; then
  sed -i '/^Renderer =/c\Renderer = -1' "$CFG"
fi
if [ "$GRENDERER" = "1" ]; then
  sed -i '/^Renderer =/c\Renderer = 12' "$CFG"
fi
if [ "$GRENDERER" = "2" ]; then
  sed -i '/^Renderer =/c\Renderer = 14' "$CFG"
fi
if [ "$GRENDERER" = "3" ]; then
  sed -i '/^Renderer =/c\Renderer = 13' "$CFG"
fi

#Internal Resolution (FIXED)
if [ -n "$IRES" ] && [ "$IRES" -gt 0 ]; then
  sed -i "/^upscale_multiplier =/c\upscale_multiplier = $IRES" "$CFG"
else
  sed -i '/^upscale_multiplier =/c\upscale_multiplier = 1' "$CFG"
fi

#Show FPS
if [ "$FPS" = "false" ]; then
  sed -i '/^OsdShowFPS =/c\OsdShowFPS = false' "$CFG"
fi
if [ "$FPS" = "true" ]; then
  sed -i '/^OsdShowFPS =/c\OsdShowFPS = true' "$CFG"
fi

#EE Cycle Rate
sed -i '/^EECycleRate =/c\EECycleRate = 0' "$CFG"
if [ "$RATE" = "0" ]; then sed -i '/^EECycleRate =/c\EECycleRate = -3' "$CFG"; fi
if [ "$RATE" = "1" ]; then sed -i '/^EECycleRate =/c\EECycleRate = -2' "$CFG"; fi
if [ "$RATE" = "2" ]; then sed -i '/^EECycleRate =/c\EECycleRate = -1' "$CFG"; fi
if [ "$RATE" = "3" ]; then sed -i '/^EECycleRate =/c\EECycleRate = 0' "$CFG"; fi
if [ "$RATE" = "4" ]; then sed -i '/^EECycleRate =/c\EECycleRate = 1' "$CFG"; fi
if [ "$RATE" = "5" ]; then sed -i '/^EECycleRate =/c\EECycleRate = 2' "$CFG"; fi
if [ "$RATE" = "6" ]; then sed -i '/^EECycleRate =/c\EECycleRate = 3' "$CFG"; fi

#EE Cycle Skip
sed -i '/^EECycleSkip =/c\EECycleSkip = 0' "$CFG"
if [ -n "$SKIP" ]; then
  sed -i "/^EECycleSkip =/c\EECycleSkip = $SKIP" "$CFG"
fi

#Set OpenGL 3.3 on panfrost
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330

#Set QT environment to wayland
export QT_QPA_PLATFORM=wayland

#Run Aethersx2 emulator
export SDL_AUDIODRIVER=pulseaudio
set_kill_keys "aethersx2-sa"

exec ${EMUPERF} "$APP" -fullscreen "$1"
