# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="xow"
PKG_VERSION="1.0"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/medusalix/xow"
PKG_DEPENDS_TARGET="toolchain"
PKG_SHORTDESC="Stub package for xow (disabled)"
PKG_LONGDESC="Empty package to satisfy dependency without building xow"
PKG_TOOLCHAIN="manual"

make_target() {
  :
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
}