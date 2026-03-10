# SPDX-License-Identifier: GPL-2.0

PKG_NAME="usb-modeswitch"
PKG_VERSION="1.0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="dummy"
PKG_URL=""
PKG_DEPENDS_TARGET=""
PKG_SECTION="sysutils"
PKG_SHORTDESC="usb-modeswitch dummy"
PKG_LONGDESC="Dummy package to satisfy dependency"
PKG_TOOLCHAIN="manual"

unpack() {
  mkdir -p ${PKG_BUILD}
}

make_target() {
  :
}

makeinstall_target() {
  :
}