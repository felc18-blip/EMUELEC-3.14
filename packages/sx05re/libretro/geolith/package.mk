# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present ArchR (https://github.com/archr-linux/Arch-R)

PKG_NAME="geolith"
PKG_VERSION="95685d32ab6a143442580164d97fb1d01fe1b6d2"
PKG_ARCH="aarch64"
PKG_LICENSE="BSD"
PKG_SITE="https://github.com/libretro/geolith-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Geolith is a highly accurate emulator for the Neo Geo AES and MVS."
PKG_TOOLCHAIN="make"

make_target() {
cd libretro
  make -f ./Makefile platform=rpi3_64
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp geolith_libretro.so ${INSTALL}/usr/lib/libretro/
}
