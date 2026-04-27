#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS launcher for Kronos (Sega Saturn / ST-V).
# Roda Qt5 em eglfs (GLES2 puro) e força VIDSoft — VIDOGL do Kronos
# precisa GL 4.3+ com compute shaders, sem chance no Mali-450.

. /etc/profile

KRONOS_CFG_DIR="/storage/.config/emuelec/configs/kronos/qt"
KRONOS_BIOS_DIR="/storage/roms/bios/kronos"
ROM_DIR="/storage/roms/saturn/kronos"
SOURCE_DIR="/usr/config/emuelec/configs/kronos/qt"

ROM="${1}"
PLATFORM="${2:-saturn}"
GAME=$(basename "${ROM}")

init_game

mkdir -p "${ROM_DIR}" "${KRONOS_BIOS_DIR}" "${KRONOS_CFG_DIR}"

# First-run seed do kronos.ini
if [ ! -e "${KRONOS_CFG_DIR}/kronos.ini" ] && [ -f "${SOURCE_DIR}/kronos.ini" ]; then
  cp -f "${SOURCE_DIR}/kronos.ini" "${KRONOS_CFG_DIR}/kronos.ini"
fi

# HLE BIOS (idem yabasanshiro): se 0 e tem saturn_bios.bin no /storage/roms/bios,
# passa explicitamente; senão deixa Kronos cair pro HLE.
USE_BIOS=$(get_ee_setting use_hlebios saturn "${GAME}")
[ -z "${USE_BIOS}" ] && USE_BIOS=$(get_ee_setting use_hlebios saturn)
BIOS_ARG=""
if [ "${USE_BIOS}" != "1" ] && [ -f "/storage/roms/bios/saturn_bios.bin" ]; then
  BIOS_ARG="-b /storage/roms/bios/saturn_bios.bin"
fi

# Auto-frameskip
USE_SKIP=$(get_ee_setting use_autoskip saturn "${GAME}")
AUTOSKIP=""
[ "${USE_SKIP}" = "1" ] && AUTOSKIP="-autoframeskip 1"

# Em Mali-450 só VideoCore=2 (VIDSoft) é viável. Ignoramos qualquer
# tentativa de habilitar opengl pelas opções do EmuStation.
sed -i 's~Video\\VideoCore=.*$~Video\\VideoCore=2~g' "${KRONOS_CFG_DIR}/kronos.ini"
# Sem Vulkan, sem compute shader, sem tessellation GPU.
sed -i 's~Video\\compute_shader_mode=.*$~Video\\compute_shader_mode=0~g' "${KRONOS_CFG_DIR}/kronos.ini"
sed -i 's~Video\\polygon_generation_mode=.*$~Video\\polygon_generation_mode=1~g' "${KRONOS_CFG_DIR}/kronos.ini"

# Áudio: NextOS roda PulseAudio system-mode. SoundCore=4 (OpenAL) ou 1 (SDL).
# OpenAL aqui passa por openal-soft → ALSA dmix → pulse, dá pra trocar.
AUDIO_DRIVER=$(get_ee_setting audio_driver saturn "${GAME}")
case "${AUDIO_DRIVER}" in
  openal) sed -i 's~Sound\\SoundCore=.*$~Sound\\SoundCore=4~g' "${KRONOS_CFG_DIR}/kronos.ini" ;;
  *)      sed -i 's~Sound\\SoundCore=.*$~Sound\\SoundCore=1~g' "${KRONOS_CFG_DIR}/kronos.ini" ;;
esac

SHOW_FPS=$(get_ee_setting show_fps saturn "${GAME}")
case "${SHOW_FPS}" in
  1) sed -i 's~General\\ShowFPS=.*$~General\\ShowFPS=true~g'  "${KRONOS_CFG_DIR}/kronos.ini" ;;
  *) sed -i 's~General\\ShowFPS=.*$~General\\ShowFPS=false~g' "${KRONOS_CFG_DIR}/kronos.ini" ;;
esac

USE_VSYNC=$(get_ee_setting use_vsync saturn "${GAME}")
case "${USE_VSYNC}" in
  1) sed -i 's~General\\EnableVSync=.*$~General\\EnableVSync=true~g'  "${KRONOS_CFG_DIR}/kronos.ini" ;;
  *) sed -i 's~General\\EnableVSync=.*$~General\\EnableVSync=false~g' "${KRONOS_CFG_DIR}/kronos.ini" ;;
esac

ACTIVE_THREADS=$(grep -c processor /proc/cpuinfo)
sed -i 's~General\\NumThreads=.*$~General\\NumThreads='${ACTIVE_THREADS}'~g' "${KRONOS_CFG_DIR}/kronos.ini"

# Qt eglfs → contexto GLES2 puro no fbdev do Mali blob.
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_HIDECURSOR=1
export QT_QPA_EGLFS_FB=/dev/fb0
export QT_QPA_EGLFS_INTEGRATION=eglfs_mali
# Pede surface GLES2 explícito caso algum widget tente desktop GL.
export QSG_RHI_BACKEND=opengles2
export QT_OPENGL=es2
# Usa diretório de config consistente
export XDG_CONFIG_HOME="/storage/.config"

# NextOS LD_PRELOAD shim: Qt 5.15 EGLFS pede EGL_RENDERABLE_TYPE=8 (desktop
# GL) em QOpenGLWidget filhos mesmo com setRenderableType(OpenGLES). Mali
# blob não tem configs com RENDER=8 → 'Cannot find EGLConfig' e tela preta.
# Shim re-escreve cada eglChooseConfig pra forçar RENDER=4 (ES2).
export LD_PRELOAD="/usr/lib/libkronos-eglshim.so"

cd "${KRONOS_CFG_DIR}"
{ nice -n -19 ionice -c 1 -n 0 /usr/bin/kronos -a -f -i "${ROM}" ${BIOS_ARG} ${AUTOSKIP}; } \
  >>/emuelec/logs/emuelec.log 2>&1
RET=$?

end_game
exit ${RET}
