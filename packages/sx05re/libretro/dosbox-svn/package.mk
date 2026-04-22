################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
################################################################################

PKG_NAME="dosbox-svn"
PKG_VERSION="53ca2f6303a652d129321cfc521f000cd7ec5531"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/dosbox-svn"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="libretro"
PKG_DEPENDS_TARGET="toolchain sdl12-compat SDL_net retroarch"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="Upstream port of DOSBox to libretro"
PKG_LONGDESC="Upstream port of DOSBox to libretro"
GET_HANDLER_SUPPORT="git"
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"
PKG_BUILD_FLAGS="-lto"
PKG_TOOLCHAIN="make"

make_target() {
  if [ "${ARCH}" = "aarch64" ]; then
    make -C libretro target=arm64 WITH_EMBEDDED_SDL=0 WITH_FAKE_SDL=1
  elif [ "${ARCH}" = "arm" ]; then
    make -C libretro target=arm WITH_EMBEDDED_SDL=0 WITH_FAKE_SDL=1
  elif [ "${ARCH}" = "x86_64" ]; then
    make -C libretro target=x86_64 WITH_EMBEDDED_SDL=0
  elif [ "${ARCH}" = "i386" ]; then
    make -C libretro target=x86 WITH_EMBEDDED_SDL=0
  else
    make -C libretro WITH_EMBEDDED_SDL=0 WITH_FAKE_SDL=1
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/libretro/dosbox_svn_libretro.so ${INSTALL}/usr/lib/libretro
}
