# SPDX-License-Identifier: GPL-2.0-or-later
# EmuELEC / LibreELEC package for JAXE libretro core

PKG_NAME="jaxe"
PKG_VERSION="581befc5d7273abc20ea1b137744f414aa70592c"
PKG_ARCH="any"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/kurtjd/jaxe"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_DEPTH="1"

PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="emuelec/libretro"
PKG_SHORTDESC="JAXE CHIP-8/S-CHIP/XO-CHIP libretro core"
PKG_LONGDESC="JAXE is a CHIP-8 / S-CHIP / XO-CHIP emulator with a libretro frontend."

PKG_TOOLCHAIN="make"

post_unpack() {
  cd "${PKG_BUILD}"
  git submodule update --init --recursive
}

make_target() {
  cd "${PKG_BUILD}"

  make -f Makefile.libretro \
    CC="${CC}" \
    CXX="${CXX}" \
    AR="${AR}" \
    RANLIB="${RANLIB}" \
    platform=unix
}

makeinstall_target() {
  mkdir -p "${INSTALL}/usr/lib/libretro"
  cp "${PKG_BUILD}/jaxe_libretro.so" "${INSTALL}/usr/lib/libretro/"
}
