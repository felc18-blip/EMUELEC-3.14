# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC

PKG_NAME="lib32-opus"
PKG_VERSION="$(get_pkg_version opus)"
PKG_NEED_UNPACK="$(get_pkg_directory opus)"
PKG_ARCH="aarch64"
PKG_LICENSE="BSD"
PKG_SITE="http://www.opus-codec.org"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain"
PKG_PATCH_DIRS+=" $(get_pkg_directory opus)/patches"
PKG_LONGDESC="Codec designed for interactive speech and audio transmission over the Internet."
PKG_TOOLCHAIN="configure"
PKG_BUILD_FLAGS="lib32 +pic"

PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --disable-shared \
                           --enable-fixed-point \
                           --disable-intrinsics \
                           --disable-asm"

unpack() {
  ${SCRIPTS}/get opus
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/opus/opus-${PKG_VERSION}.tar.gz -C ${PKG_BUILD}
}

pre_configure_target() {
  # limpa qualquer lixo anterior
  export CFLAGS="${CFLAGS} -UOPUS_ARM_MAY_HAVE_NEON -DOPUS_ARM_MAY_HAVE_NEON=0"
  export CXXFLAGS="${CXXFLAGS} -UOPUS_ARM_MAY_HAVE_NEON -DOPUS_ARM_MAY_HAVE_NEON=0"
}

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/include
  safe_remove ${INSTALL}/usr/share
  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}
