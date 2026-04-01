# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="u-boot-tools"
PKG_VERSION="2025.04"
PKG_SHA256="439d3bef296effd54130be6a731c5b118be7fddd7fcc663ccbc5fb18294d8718"
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://www.denx.de/wiki/U-Boot"
PKG_URL="https://ftp.denx.de/pub/u-boot/u-boot-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_HOST="gcc:host"
PKG_DEPENDS_TARGET="toolchain u-boot-tools-aml:host"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems (Amlogic tools version)."

make_host() {
  make mrproper
  make tools-only_defconfig
  make tools-only NO_SDL=1
}

make_target() {
  make mrproper
  CROSS_COMPILE="$TARGET_PREFIX" ARCH=arm make tools-only_defconfig
  CROSS_COMPILE="$TARGET_PREFIX" ARCH=arm make envtools
}

makeinstall_host() {
  mkdir -p $TOOLCHAIN/bin
    cp tools/mkimage $TOOLCHAIN/bin/
    cp tools/mkenvimage $TOOLCHAIN/bin/
}

makeinstall_target() {
  mkdir -p $INSTALL/etc
    [ -f $PKG_DIR/config/fw_env.config ] && cp $PKG_DIR/config/fw_env.config $INSTALL/etc/fw_env.config

  mkdir -p $INSTALL/usr/sbin
    cp tools/env/fw_printenv $INSTALL/usr/sbin/fw_printenv
    ln -sf fw_printenv $INSTALL/usr/sbin/fw_setenv
}
