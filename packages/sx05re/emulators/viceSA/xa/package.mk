# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="xa"
PKG_VERSION="2.4.1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://www.floodgap.com/retrotech/xa/"
PKG_URL="${PKG_SITE}/dists/xa-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain"
PKG_DEPENDS_HOST="toolchain"

PKG_SECTION="tools"
PKG_SHORTDESC="6502 cross-assembler"

PKG_TOOLCHAIN="make"

# garante build
make_target() {
  make
}

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/bin

  for bin in file65 ldo65 mkrom.sh printcbm reloc65 uncpk xa; do
    if [ -f "$bin" ]; then
      cp -f $bin ${TOOLCHAIN}/bin/
    fi
  done
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin

  for bin in file65 ldo65 mkrom.sh printcbm reloc65 uncpk xa; do
    if [ -f "$bin" ]; then
      cp -f $bin ${INSTALL}/usr/bin/
    fi
  done
}