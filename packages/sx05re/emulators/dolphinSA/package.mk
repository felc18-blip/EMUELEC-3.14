# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="dolphinSA"
PKG_LICENSE="GPLv2"

PKG_SITE="https://github.com/rtissera/dolphin"
PKG_URL="${PKG_SITE}.git"
PKG_VERSION="0b160db48796f727311cea16072174d96b784f80"
PKG_GIT_CLONE_BRANCH="egldrm"

PKG_DEPENDS_TARGET="toolchain libevdev ffmpeg zlib libpng lzo libusb zstd ecm openal-soft alsa-lib"

PKG_LONGDESC="Dolphin is a GameCube / Wii emulator."

PKG_TOOLCHAIN="cmake"

PKG_PATCH_DIRS+=" legacy"

PKG_DEPENDS_TARGET+=" ${OPENGLES}"

PKG_CMAKE_OPTS_TARGET+=" -DENABLE_EGL=ON \
                         -DENABLE_VULKAN=OFF \
                         -DENABLE_X11=OFF \
                         -DENABLE_WAYLAND=OFF \
                         -DENABLE_HEADLESS=ON \
                         -DENABLE_EVDEV=ON \
                         -DUSE_DISCORD_PRESENCE=OFF \
                         -DBUILD_SHARED_LIBS=OFF \
                         -DLINUX_LOCAL_DEV=ON \
                         -DENABLE_PULSEAUDIO=OFF \
                         -DENABLE_ALSA=ON \
                         -DENABLE_TESTS=OFF \
                         -DENABLE_LLVM=OFF \
                         -DENABLE_ANALYTICS=OFF \
                         -DENABLE_LTO=ON \
                         -DENABLE_QT=OFF \
                         -DENCODE_FRAMEDUMPS=OFF \
                         -DENABLE_CLI_TOOL=OFF \
                         -DCMAKE_BUILD_TYPE=Release"

pre_make_target() {
  # Esta função roda DEPOIS do cmake, mas ANTES da compilação (ninja)
  
  # 1. Correção para Kernel 3.14 (Erro do INPUT_PROP_ACCELEROMETER)
  EVDEV_FILE="${PKG_BUILD}/Source/Core/InputCommon/ControllerInterface/evdev/evdev.cpp"
  if [ -f "${EVDEV_FILE}" ]; then
    echo "Aplicando patch de compatibilidade para evdev no Kernel 3.14..."
    sed -i 's/libevdev_has_property(dev, INPUT_PROP_ACCELEROMETER)/false/g' "${EVDEV_FILE}"
  fi

  # 2. Correção de headers para dispositivos específicos
  case ${DEVICE} in
    RK3588*|AMD64|S922X|Amlogic-old)
      VMA_FILE="${PKG_BUILD}/Externals/VulkanMemoryAllocator/include/vk_mem_alloc.h"
      if [ -f "${VMA_FILE}" ]; then
        sed -i 's~#include <cstdlib>~#include <cstdlib>\n#include <cstdint>~g' "${VMA_FILE}"
        sed -i 's~#include <cstdint>~#include <cstdint>\n#include <string>~g' "${VMA_FILE}"
      fi
    ;;
  esac
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/Binaries/dolphin* ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

  chmod +x ${INSTALL}/usr/bin/start_dolphin_gc.sh
  chmod +x ${INSTALL}/usr/bin/start_dolphin_wii.sh

  mkdir -p ${INSTALL}/usr/config/dolphin-emu
  cp -rf ${PKG_BUILD}/Data/Sys/* ${INSTALL}/usr/config/dolphin-emu
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/dolphin-emu
}

post_install() {
  DOLPHIN_PLATFORM="drm"
  sed -e "s/@DOLPHIN_PLATFORM@/${DOLPHIN_PLATFORM}/g" \
      -i ${INSTALL}/usr/bin/start_dolphin_gc.sh

  sed -e "s/@DOLPHIN_PLATFORM@/${DOLPHIN_PLATFORM}/g" \
      -i ${INSTALL}/usr/bin/start_dolphin_wii.sh
}