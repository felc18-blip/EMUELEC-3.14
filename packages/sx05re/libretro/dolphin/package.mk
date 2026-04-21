# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="dolphin"
PKG_VERSION="0cd3bb89c29535db9b7552fc86871867ccf5b471"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
# Corrigi aqui para não sobrescrever a variável de dependências abaixo
PKG_DEPENDS_TARGET="toolchain libevdev libdrm ffmpeg zlib libpng lzo libusb"
PKG_SITE="https://github.com/libretro/dolphin"
PKG_URL="${PKG_SITE}.git"
PKG_SECTION="libretro"
PKG_SHORTDESC="Dolphin Libretro, a Gamecube & Wii emulator core for Retroarch"
PKG_TOOLCHAIN="cmake"

if [ ! "${OPENGL}" = "no" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
  # ALTERADO: PKG_CONFIGURE_OPTS_TARGET -> PKG_CMAKE_OPTS_TARGET
  PKG_CMAKE_OPTS_TARGET+=" -DENABLE_X11=OFF \
                           -DENABLE_EGL=ON"
fi

if [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  # ALTERADO: PKG_CONFIGURE_OPTS_TARGET -> PKG_CMAKE_OPTS_TARGET
  PKG_CMAKE_OPTS_TARGET+=" -DENABLE_X11=OFF \
                           -DENABLE_EGL=ON"
fi

if [ "${DISPLAYSERVER}" = "wl" ]; then
  PKG_DEPENDS_TARGET+=" wayland ${WINDOWMANAGER} xwayland xrandr libXi"
  # ALTERADO: PKG_CONFIGURE_OPTS_TARGET -> PKG_CMAKE_OPTS_TARGET
  PKG_CMAKE_OPTS_TARGET+=" -DENABLE_X11=ON \
                           -DENABLE_EGL=ON"
fi

if [ "${VULKAN_SUPPORT}" = "yes" ]
then
  PKG_DEPENDS_TARGET+=" vulkan-loader vulkan-headers"
  # ALTERADO: PKG_CONFIGURE_OPTS_TARGET -> PKG_CMAKE_OPTS_TARGET
  PKG_CMAKE_OPTS_TARGET+=" -DENABLE_VULKAN=ON"
fi

post_unpack() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive
}

pre_configure_target() {
  # Mantenha as opções aqui, elas serão anexadas às definidas acima
  PKG_CMAKE_OPTS_TARGET+=" -DENABLE_EGL=ON \
                           -DUSE_SHARED_ENET=OFF \
                           -DUSE_UPNP=ON \
                           -DENABLE_NOGUI=ON \
                           -DENABLE_QT=OFF \
                           -DENABLE_LTO=ON \
                           -DENABLE_GENERIC=OFF \
                           -DENABLE_HEADLESS=ON \
                           -DENABLE_ALSA=ON \
                           -DENABLE_PULSEAUDIO=ON \
                           -DENABLE_LLVM=OFF \
                           -DENABLE_TESTS=OFF \
                           -DUSE_DISCORD_PRESENCE=OFF \
                           -DLIBRETRO=ON"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/.${TARGET_NAME}/dolphin_libretro.so ${INSTALL}/usr/lib/libretro/
}
