# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="libcap-ng"
PKG_VERSION="0.8.3"
PKG_SHA256="bed6f6848e22bb2f83b5f764b2aef0ed393054e803a8e3a8711cb2a39e6b492d"
PKG_LICENSE="LGPL"
PKG_SITE="https://people.redhat.com/sgrubb/libcap-ng/"
PKG_URL="https://people.redhat.com/sgrubb/libcap-ng/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Library for Linux capabilities"

PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--disable-static"