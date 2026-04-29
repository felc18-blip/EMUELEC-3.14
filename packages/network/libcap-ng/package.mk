# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="libcap-ng"
PKG_VERSION="0.9.3"
PKG_SHA256="fe11ebbb55904763b3532f19069f13ec319042634620180a03bd4653d301563e"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/stevegrubb/libcap-ng"
PKG_URL="https://github.com/stevegrubb/libcap-ng/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Library for Linux capabilities"

PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--disable-static"