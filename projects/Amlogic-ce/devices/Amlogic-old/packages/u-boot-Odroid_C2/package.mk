# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="u-boot-Odroid_C2"
PKG_VERSION="a2eb29f823e8cfc6fee325f69116334c6f1ba6c0"
PKG_SHA256="a7b9d7dc7f3048dc5479dc90c094760d03f4a8e83db86823d8f951f53641cf69"
PKG_LICENSE="GPL"
PKG_SITE="https://www.denx.de/wiki/U-Boot"
PKG_URL="https://github.com/CoreELEC/u-boot/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain gcc-linaro-aarch64-elf:host gcc-linaro-arm-eabi:host u-boot_firmware"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems."
PKG_TOOLCHAIN="manual"

configure_package() {
  PKG_UBOOT_CONFIG="odroidc2_defconfig"
}

pre_configure_target() {
  cp -r $(get_build_dir u-boot_firmware)/* $PKG_BUILD
}

pre_make_target() {
  # Corrige o prefixo do toolchain
  sed -i "s|arm-none-eabi-|arm-eabi-|g" $PKG_BUILD/Makefile $PKG_BUILD/arch/arm/cpu/armv8/*/firmware/scp_task/Makefile 2>/dev/null || true

  # Race em make -j: "all : clean $(obj)/..." faz o clean apagar o dir
  # enquanto os outros targets estao escrevendo arquivos nele. Tira o
  # clean da dep de all para evitar a corrida.
  for scp_mk in $PKG_BUILD/arch/arm/cpu/armv8/*/firmware/scp_task/Makefile; do
    [ -f "$scp_mk" ] && sed -i 's|^all : clean |all : |' "$scp_mk"
  done

  # Tática Ninja: Isola os headers do libfdt
  echo ">>> Creating shadow includes for libfdt isolation..."
  mkdir -p $PKG_BUILD/shadow_include
  cp $PKG_BUILD/include/libfdt*.h $PKG_BUILD/shadow_include/ 2>/dev/null || true
  cp $PKG_BUILD/include/fdt.h $PKG_BUILD/shadow_include/ 2>/dev/null || true
}

make_target() {
  [ "${BUILD_WITH_DEBUG}" = "yes" ] && PKG_DEBUG=1 || PKG_DEBUG=0
  export PATH=$TOOLCHAIN/lib/gcc-linaro-aarch64-elf/bin/:$TOOLCHAIN/lib/gcc-linaro-arm-eabi/bin/:$PATH

  export HOSTCFLAGS="-O2 -I$PKG_BUILD/shadow_include"

  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make mrproper
  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make $PKG_UBOOT_CONFIG

  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make HOSTCC="$HOST_CC" HOSTCFLAGS="$HOSTCFLAGS" HOSTSTRIP="true"
}

post_make_target() {
  echo ">>> Exposing ALL expected FIP binaries to the root build dir..."
  # O meta-pacote do EmuELEC não perdoa e exige a versão sd.bin.
  # Clonamos o FIP funcional (u-boot.bin) para satisfazer todos os requisitos.
  cp -f $PKG_BUILD/fip/gxb/u-boot.bin $PKG_BUILD/u-boot.bin
  cp -f $PKG_BUILD/fip/gxb/u-boot.bin $PKG_BUILD/u-boot.bin.sd.bin
  cp -f $PKG_BUILD/fip/gxb/u-boot.bin $PKG_BUILD/u-boot.bin.usb.bl2
}

makeinstall_target() {
  : # nothing
}
