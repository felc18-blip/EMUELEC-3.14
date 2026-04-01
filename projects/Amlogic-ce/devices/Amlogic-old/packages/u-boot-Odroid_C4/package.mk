# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="u-boot-Odroid_C4"
PKG_VERSION="43d26e1865333916d7889a586948e11b83b2c558"
PKG_SHA256="7258b7443d4b8ea2e7d9543c076ecf3cf53c546cff6138cd5f770a536dcabf1f"
PKG_LICENSE="GPL"
PKG_SITE="https://www.denx.de/wiki/U-Boot"
PKG_URL="https://github.com/CoreELEC/u-boot/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain gcc-linaro-aarch64-elf:host gcc-linaro-arm-eabi:host u-boot_firmware"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems."
PKG_TOOLCHAIN="manual"

configure_package() {
  PKG_UBOOT_CONFIG="odroidc4_defconfig"
}

pre_configure_target() {
  # Copia o firmware necessário (FIP/BL) para a pasta de build
  cp -r $(get_build_dir u-boot_firmware)/* $PKG_BUILD
}

pre_make_target() {
  # 1. Corrige o prefixo do toolchain para o formato do EmuELEC
  sed -i "s|arm-none-eabi-|arm-eabi-|g" $PKG_BUILD/Makefile $PKG_BUILD/arch/arm/cpu/armv8/*/firmware/scp_task/Makefile 2>/dev/null || true

  # 2. Tática Ninja: Isola os headers do libfdt (Para evitar redefinições no Arch Linux)
  echo ">>> Creating shadow includes for libfdt isolation (C4 Style)..."
  mkdir -p $PKG_BUILD/shadow_include
  cp $PKG_BUILD/include/libfdt*.h $PKG_BUILD/shadow_include/ 2>/dev/null || true
  cp $PKG_BUILD/include/fdt.h $PKG_BUILD/shadow_include/ 2>/dev/null || true

  # 3. Vacina contra o conflito global: garante que o código aponte para o local certo
  find $PKG_BUILD -name "*.c" -o -name "*.h" | xargs sed -i 's|<libfdt.h>|"libfdt.h"|g' 2>/dev/null || true
}

make_target() {
  [ "${BUILD_WITH_DEBUG}" = "yes" ] && PKG_DEBUG=1 || PKG_DEBUG=0

  # Garante que os compiladores linaro estejam no PATH
  export PATH=$TOOLCHAIN/lib/gcc-linaro-aarch64-elf/bin/:$TOOLCHAIN/lib/gcc-linaro-arm-eabi/bin/:$PATH

  # Força o compilador a usar a nossa pasta de sombra antes de qualquer outra
  export HOSTCFLAGS="-O2 -I$PKG_BUILD/shadow_include"

  echo "--- INICIANDO COMPILAÇÃO DO U-BOOT ODROID C4 ---"

  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make mrproper
  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make $PKG_UBOOT_CONFIG
  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make HOSTCC="$HOST_CC" HOSTCFLAGS="$HOSTCFLAGS" HOSTSTRIP="true"
}

post_make_target() {
  echo ">>> Exposing FIP binaries for Odroid C4 (SM1)..."
  # Para o C4, o binário final fica em fip/sm1/
  if [ -f "$PKG_BUILD/fip/sm1/u-boot.bin" ]; then
    cp -f $PKG_BUILD/fip/sm1/u-boot.bin $PKG_BUILD/u-boot.bin
    cp -f $PKG_BUILD/fip/sm1/u-boot.bin $PKG_BUILD/u-boot.bin.sd.bin
    cp -f $PKG_BUILD/fip/sm1/u-boot.bin $PKG_BUILD/u-boot.bin.usb.bl2
  fi
}

makeinstall_target() {
  : # nothing
}
