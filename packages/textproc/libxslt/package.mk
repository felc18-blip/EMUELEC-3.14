# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libxslt"
PKG_VERSION="1.1.45"
PKG_SHA256="9acfe68419c4d06a45c550321b3212762d92f41465062ca4ea19e632ee5d216e"
PKG_LICENSE="MIT"
PKG_SITE="http://xmlsoft.org/xslt/"
PKG_URL="https://download.gnome.org/sources/libxslt/$(get_pkg_version_maj_min)/libxslt-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="libxml2:host"
PKG_DEPENDS_TARGET="toolchain libxml2"
PKG_LONGDESC="A XSLT C library."
PKG_BUILD_FLAGS="+pic"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_HOST="  ac_cv_header_ansidecl_h=no \
                           ac_cv_header_xlocale_h=no \
                           --enable-static \
                           --disable-shared \
                           --without-python \
                           --with-libxml-prefix=${TOOLCHAIN} \
                           --without-crypto"

PKG_CONFIGURE_OPTS_TARGET="ac_cv_header_ansidecl_h=no \
                           ac_cv_header_xlocale_h=no \
                           --enable-static \
                           --disable-shared \
                           --without-python \
                           --with-libxml-prefix=${SYSROOT_PREFIX}/usr \
                           --without-crypto"

post_makeinstall_target() {
  sed -e "s:\(['= ]\)/usr:\\1${SYSROOT_PREFIX}/usr:g" -i ${SYSROOT_PREFIX}/usr/bin/xslt-config

  rm -rf ${INSTALL}/usr/bin/xsltproc
  rm -rf ${INSTALL}/usr/lib/xsltConf.sh
}
