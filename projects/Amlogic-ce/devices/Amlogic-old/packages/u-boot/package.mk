# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2017-2018 Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="u-boot"
PKG_VERSION="1.0"
PKG_LICENSE="GPL"
PKG_SITE="https://www.denx.de/wiki/U-Boot"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain gcc-linaro-aarch64-elf:host gcc-linaro-arm-eabi:host"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems."
PKG_TOOLCHAIN="manual"

PKG_CANUPDATE="${PROJECT}*"
[ ${PROJECT} = "Amlogic-ce" ] && PKG_CANUPDATE="${DEVICE}*"
PKG_NEED_UNPACK="$PROJECT_DIR/$PROJECT/bootloader "

for PKG_SUBDEVICE in $SUBDEVICES; do
  PKG_DEPENDS_TARGET+=" u-boot-${PKG_SUBDEVICE}"
  PKG_NEED_UNPACK+=" $(get_pkg_directory u-boot-${PKG_SUBDEVICE})"
done

make_target() {
  : # nothing
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/bootloader

  # Always install the update script
  if find_file_path bootloader/update.sh; then
    cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
    sed -e "s/@KERNEL_NAME@/$KERNEL_NAME/g" \
        -e "s/@LEGACY_KERNEL_NAME@/$LEGACY_KERNEL_NAME/g" \
        -e "s/@LEGACY_DTB_NAME@/$LEGACY_DTB_NAME/g" \
        -i $INSTALL/usr/share/bootloader/update.sh
  fi

  # Always install the canupdate script
  if find_file_path bootloader/canupdate.sh; then
    cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
  fi

for PKG_SUBDEVICE in $SUBDEVICES; do
    find_file_path bootloader/${PKG_SUBDEVICE}_boot.ini && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader || true

    # 1. Definimos a base do seu projeto no Arch
    BASE_BUILD="/home/felipe/NextOS-Elite-Edition/build.EmuELEC-Amlogic-old.aarch64-4/build"

    # 2. Buscamos a pasta do Odroid_C4 ignorando o hash do final
    UBOOT_BUILD_PATH=$(ls -d ${BASE_BUILD}/u-boot-${PKG_SUBDEVICE}-* 2>/dev/null | tail -n 1)

    echo ">>> DEBUG: Verificando pasta: ${UBOOT_BUILD_PATH}"

    # 3. Lista de alvos (Focando no que vimos no seu log: sd_fuse/u-boot.bin)
    PKG_UBOOTBIN=""
    if [ -f "${UBOOT_BUILD_PATH}/sd_fuse/u-boot.bin" ]; then
      PKG_UBOOTBIN="${UBOOT_BUILD_PATH}/sd_fuse/u-boot.bin"
    elif [ -f "${UBOOT_BUILD_PATH}/u-boot.bin.sd.bin" ]; then
      PKG_UBOOTBIN="${UBOOT_BUILD_PATH}/u-boot.bin.sd.bin"
    fi

    if [ -n "${PKG_UBOOTBIN}" ]; then
      echo ">>> OK: Encontrado binário em ${PKG_UBOOTBIN}"
      mkdir -p $INSTALL/usr/share/bootloader
      cp -v ${PKG_UBOOTBIN} $INSTALL/usr/share/bootloader/${PKG_SUBDEVICE}_u-boot
    else
      echo "ERRO: u-boot não encontrado em ${UBOOT_BUILD_PATH}"
      # Se falhar, vamos listar o que tem na pasta para você ver no log
      echo "Conteúdo da pasta de build:"
      ls -R ${UBOOT_BUILD_PATH} | grep u-boot.bin
      exit 1
    fi
    PKG_CANUPDATE+="|${PKG_SUBDEVICE}*"
  done

  find_file_path bootloader/config.ini && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader || true

  if [ -f $INSTALL/usr/share/bootloader/canupdate.sh ]; then
    sed -e "s/@PROJECT@/${PKG_CANUPDATE}/g" \
        -i $INSTALL/usr/share/bootloader/canupdate.sh
  fi

  # A TÁTICA FINAL: Adicionamos "|| true" para que imagens ausentes não quebrem o build!
  find_file_path splash/boot-logo.bmp.gz && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader || true
  find_file_path splash/boot-logo-1080.bmp.gz && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader || true
  find_file_path splash/timeout-logo-1080.bmp.gz && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader || true
}
