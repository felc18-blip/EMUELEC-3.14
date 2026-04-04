# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)

PKG_NAME="mame2003-midway-lr"
PKG_VERSION="3a47c3d8b44d3ced80a8b4907cc7bc75d9a738fd"
PKG_SHA256="2e9154db99675190e1d3b685b738627e3116fbcfe4f590a4a071d5bd1a935c09"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MAME"
PKG_SITE="https://github.com/libretro/mame2003_midway"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="MAME - Multiple Arcade Machine Emulator"
PKG_LONGDESC="MAME - Multiple Arcade Machine Emulator"

PKG_IS_ADDON="no"
PKG_TOOLCHAIN="make"
PKG_AUTORECONF="no"
PKG_BUILD_FLAGS="-lto"

make_target() {
  # Adicionamos -Isrc -Isrc/includes -Isrc/libretro para garantir que os headers sejam achados
  # A flag -Dstricmp=strcasecmp ajuda na compatibilidade de strings
  export CFLAGS="$CFLAGS -std=gnu11 -fcommon -Wno-error -Wno-implicit-function-declaration -Isrc -Isrc/includes -Isrc/libretro -Dstricmp=strcasecmp"
  export CXXFLAGS="$CXXFLAGS -std=gnu11 -fcommon -Wno-error -Wno-implicit-function-declaration -Isrc -Isrc/includes -Isrc/libretro -Dstricmp=strcasecmp"

  # Chamamos o make sem passar CFLAGS na linha de comando para não sobrescrever o que o Makefile faz internamente
  make ARCH="" \
       CC="${CC}" \
       NATIVE_CC="${CC}" \
       LD="${CC}" \
       -j 1
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mame2003_midway_libretro.so ${INSTALL}/usr/lib/libretro/
}
