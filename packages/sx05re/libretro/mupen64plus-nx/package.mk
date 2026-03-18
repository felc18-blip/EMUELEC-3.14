# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="mupen64plus-nx"
PKG_VERSION="222acbd3f98391458a047874d0372fe78e14fe94"
PKG_SHA256="9e55fa83f2313f9b80a369d77457ec216e5774ef2d486083ad8661aa94a4dbd1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro-nx"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host ${OPENGLES}"
PKG_SECTION="libretro"
PKG_SHORTDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_LONGDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-lto"

pre_configure_target() {

  # evitar EGL puxando X11
  export CFLAGS="${CFLAGS} -DMESA_EGL_NO_X11_HEADERS"
  export CXXFLAGS="${CXXFLAGS} -DMESA_EGL_NO_X11_HEADERS"

  sed -e "s|^GIT_VERSION ?.*$|GIT_VERSION := \"${PKG_VERSION:0:7}\"|" -i Makefile

  # 🔥 FORÇA GLES (ESSENCIAL)
  PKG_MAKE_OPTS_TARGET+=" HAVE_OPENGL=0 HAVE_OPENGLES=1 HAVE_OPENGLES2=1 HAVE_EGL=1 FORCE_GLES=1"

  # ❌ DESATIVA PARALLEL (incompatível com seu sistema)
  PKG_MAKE_OPTS_TARGET+=" HAVE_PARALLEL_RDP=0 HAVE_PARALLEL_RSP=0 LLE=0"

  if [ "${ARCH}" = "arm" ]; then
    if [ "${DEVICE}" = "Amlogic-old" ]; then
      PKG_MAKE_OPTS_TARGET+=" platform=emuelec BOARD=OLD32BIT"
    else
      PKG_MAKE_OPTS_TARGET+=" platform=AMLG12B"
    fi
  else
    if [ "${DEVICE}" = "Amlogic-old" ]; then
      PKG_MAKE_OPTS_TARGET+=" platform=emuelec BOARD=OLD"
    else
      PKG_MAKE_OPTS_TARGET+=" platform=odroid64 BOARD=N2"
    fi
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_next_libretro.so ${INSTALL}/usr/lib/libretro/
}
