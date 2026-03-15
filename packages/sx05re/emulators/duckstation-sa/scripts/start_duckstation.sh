#!/bin/bash

# DuckStation starter - EmuELEC 3.14 Mali

. /etc/profile

killall -9 duckstation-nogui 2>/dev/null

CONF_PATH="/storage/.config/duckstation"
SETTINGS_INI="${CONF_PATH}/settings.ini"

mkdir -p "${CONF_PATH}"
mkdir -p /storage/roms/savestates/psx

if [ ! -f "${SETTINGS_INI}" ]; then
cp -rf /usr/config/duckstation/* "${CONF_PATH}/"
fi

ln -sf /storage/roms/savestates/psx "${CONF_PATH}/savestates"

# ajustes GLES2

sed -i '/^Renderer =/c\Renderer = OpenGL' "${SETTINGS_INI}"
sed -i '/^GLES =/c\GLES = true' "${SETTINGS_INI}"
sed -i '/^TrueColor =/c\TrueColor = false' "${SETTINGS_INI}"

# sincronizar com EmulationStation

ASPECT=$(get_ee_setting aspect_ratio psx)
VSYNC=$(get_ee_setting vsync psx)

case "${ASPECT}" in
"0") sed -i '/^AspectRatio/c\AspectRatio = 4:3' "${SETTINGS_INI}" ;;
"1") sed -i '/^AspectRatio/c\AspectRatio = 16:9' "${SETTINGS_INI}" ;;
*) sed -i '/^AspectRatio/c\AspectRatio = Auto (Game Native)' "${SETTINGS_INI}" ;;
esac

if [ "${VSYNC}" = "on" ]; then
sed -i '/^VSync =/c\VSync = true' "${SETTINGS_INI}"
else
sed -i '/^VSync =/c\VSync = false' "${SETTINGS_INI}"
fi

# ambiente Mali

export SDL_AUDIODRIVER=dummy
export SDL_VIDEODRIVER=mali

export LD_PRELOAD=/usr/lib/libMali.so
export SDL_VIDEO_EGL_DRIVER=/usr/lib/libEGL.so
export SDL_VIDEO_GL_DRIVER=/usr/lib/libGL.so

GAME="${1//[\]/}"

echo "Starting DuckStation..."

/usr/bin/duckstation-nogui -batch -fullscreen -settings "${SETTINGS_INI}" "${GAME}"
