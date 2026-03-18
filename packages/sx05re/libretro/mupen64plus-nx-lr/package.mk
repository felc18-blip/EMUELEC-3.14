# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="mupen64plus-nx-lr"
PKG_VERSION="222acbd3f98391458a047874d0372fe78e14fe94"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro-nx"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host ${OPENGLES}"
PKG_SECTION="libretro"
PKG_SHORTDESC="mupen64plus NX"
PKG_LONGDESC="mupen64plus NX"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-lto"

PKG_PATCH_DIRS+="${DEVICE}"

pre_configure_target() {

  # Fix build
  for SOURCE in ${PKG_BUILD}/mupen64plus-rsp-paraLLEl/rsp_disasm.cpp ${PKG_BUILD}/mupen64plus-rsp-paraLLEl/rsp_disasm.hpp
  do
    sed -i '/include <string>/a #include <cstdint>' ${SOURCE}
  done

  sed -e "s|^GIT_VERSION ?.*$|GIT_VERSION := \" ${PKG_VERSION:0:7}\"|" -i Makefile
  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/Makefile

  # FORÇA GLES (CRÍTICO)
  PKG_MAKE_OPTS_TARGET+=" HAVE_OPENGL=0 HAVE_OPENGLES=1 FORCE_GLES=1"

  case ${DEVICE} in
    RK3*|S922X*)
      PKG_MAKE_OPTS_TARGET+=" platform=${DEVICE}"
    ;;
  esac
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_next_libretro.so ${INSTALL}/usr/lib/libretro/mupen64plus_next-lr_libretro.so
}