# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="mupen64plus-lr"
PKG_VERSION="ab8134ac90a567581df6de4fc427dd67bfad1b17"
PKG_REV="1"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host ${OPENGLES}"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_LONGDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-lto"
PKG_PATCH_DIRS+=" ${DEVICE}"

pre_make_target() {
  export CFLAGS="${CFLAGS} -fcommon"
}

pre_configure_target() {

  # força GLES (CRÍTICO)
  PKG_MAKE_OPTS_TARGET+=" HAVE_OPENGL=0 HAVE_OPENGLES=1 FORCE_GLES=1"

  case ${DEVICE} in
    RK3*|S922X*)
      PKG_MAKE_OPTS_TARGET+=" platform=${DEVICE}"
      CFLAGS="${CFLAGS} -DLINUX -DEGL_API_FB"
      CPPFLAGS="${CPPFLAGS} -DLINUX -DEGL_API_FB"
    ;;
  esac

  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/Makefile
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_libretro.so ${INSTALL}/usr/lib/libretro/mupen64plus-lr_libretro.so
}