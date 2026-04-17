# SPDX-License-Identifier: GPL-2.0-or-later

# EmuELEC package for Mini vMac (libretro-minivmac) core

PKG_NAME="minivmac"
PKG_VERSION="ac7fdac318261e1e3464081bf300cc3db30c74af"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/libretro-minivmac"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Virtual Macintosh"
PKG_TOOLCHAIN="make"


makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/minivmac_libretro.so ${INSTALL}/usr/lib/libretro/
}
