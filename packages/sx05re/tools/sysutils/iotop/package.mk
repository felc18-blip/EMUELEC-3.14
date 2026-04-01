# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="iotop"
PKG_VERSION="4602ed3353a6479b1b7a3adfba84e09124c90d38"
PKG_SHA256="0d3593714011197e32f56953ae1dc21079126a614f90caa2a58d118137f1e8af"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/Tomas-M/iotop"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ncurses"
PKG_LONGDESC="A top utility for IO"
PKG_TOOLCHAIN="make"

make_target() {
  export CPPFLAGS="${CPPFLAGS} -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -DKEY_RESIZE=410"
  export LDFLAGS="${LDFLAGS} -lncursesw"

  make
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/sbin
  cp iotop ${INSTALL}/usr/sbin/
}
