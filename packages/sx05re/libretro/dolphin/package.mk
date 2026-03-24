# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="dolphin"
PKG_VERSION="ab0db892052b0f11b741b177d712ce3b01ff5079"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/dolphin"
PKG_URL="${PKG_SITE}.git"

PKG_SECTION="libretro"
PKG_SHORTDESC="Dolphin Libretro (GLES2 only)"

PKG_TOOLCHAIN="cmake"

# Apenas GLES
PKG_DEPENDS_TARGET="toolchain libevdev libdrm ffmpeg zlib libpng lzo libusb ${OPENGLES}"

pre_configure_target() {
    PKG_CMAKE_OPTS_TARGET+=" -DENABLE_X11=OFF \
                             -DENABLE_EGL=ON \
                             -DENABLE_VULKAN=OFF \
                             -DENABLE_OPENGL=OFF \
                             -DUSE_GLES=ON \
                             -DGLES2=ON \
                             -DUSE_SHARED_ENET=OFF \
                             -DUSE_UPNP=ON \
                             -DENABLE_NOGUI=ON \
                             -DENABLE_QT=OFF \
                             -DENABLE_LTO=ON \
                             -DENABLE_GENERIC=OFF \
                             -DENABLE_HEADLESS=ON \
                             -DENABLE_ALSA=ALSA \
                             -DENABLE_PULSEAUDIO=ON \
                             -DENABLE_LLVM=OFF \
                             -DENABLE_TESTS=OFF \
                             -DUSE_DISCORD_PRESENCE=OFF \
                             -DLIBRETRO=ON \
                             -DVIDEO_BACKEND=OGL"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/.${TARGET_NAME}/dolphin_libretro.so ${INSTALL}/usr/lib/libretro/
}