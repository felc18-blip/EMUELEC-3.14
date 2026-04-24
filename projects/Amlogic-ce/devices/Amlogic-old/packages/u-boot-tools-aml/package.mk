# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="u-boot-tools-aml"
PKG_VERSION="2026.04"
PKG_SHA256="ac7c04b8b7004923b00a4e5d6699c5df4d21233bac9fda690d8cfbc209fff2fd"
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://www.denx.de/wiki/U-Boot"
PKG_URL="https://ftp.denx.de/pub/u-boot/u-boot-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_HOST="gcc:host"
PKG_DEPENDS_TARGET="toolchain u-boot-tools-aml:host"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems (Amlogic tools version)."

post_patch() {
  echo "--- ENTRANDO NA PASTA DE BUILD E APLICANDO HACK SEGURO ---"

  cd "${PKG_BUILD}"
  TARGET="tools/env/fw_env.c"

  if [ -f "$TARGET" ]; then
    # 1. Correção do Seek (lseek) - Esta parte já estava funcionando
    sed -i 's/if (lseek(fd, blockstart, SEEK_SET) == -1)/if (blockstart != 0 \&\& lseek(fd, blockstart, SEEK_SET) == -1)/g' "$TARGET"

    # 2. O HACK SEGURO DA NAND:
    # Em vez de apagar, vamos apenas forçar o valor de MTD_ABSENT logo no início da função.
    # Vamos procurar a linha 'DEVTYPE(dev_current) = mtdinfo.type;' e injetar o hack antes dela.

    # Injetamos o hack diretamente forçando o tipo ausente na variável mtdinfo (ou mtd no Target)
    sed -i '/rc = ioctl(fd, MEMGETINFO, &mtdinfo);/a \	{ memset(&mtdinfo, 0, sizeof(mtdinfo)); mtdinfo.type = MTD_ABSENT; rc = 0; }' "$TARGET"
    sed -i '/rc = ioctl(fd, MEMGETINFO, &mtd);/a \	{ memset(&mtd, 0, sizeof(mtd)); mtd.type = MTD_ABSENT; rc = 0; }' "$TARGET"

    # 3. Vacina para o Arch Linux (LibFDT)
    sed -i 's|<libfdt.h>|"libfdt.h"|g' "$TARGET" 2>/dev/null || true

    echo "--- HACK APLICADO SEM QUEBRAR A ESTRUTURA ---"
  else
    echo "ERRO CRÍTICO: Arquivo $TARGET não encontrado!"
    exit 1
  fi
}

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
