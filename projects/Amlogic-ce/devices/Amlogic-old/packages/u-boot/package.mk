# SPDX-License-Identifier: GPL-2.0

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
  set +e

  mkdir -p $INSTALL/usr/share/bootloader

  # update.sh
  if find_file_path bootloader/update.sh; then
    cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
    sed -e "s/@KERNEL_NAME@/$KERNEL_NAME/g" \
        -e "s/@LEGACY_KERNEL_NAME@/$LEGACY_KERNEL_NAME/g" \
        -e "s/@LEGACY_DTB_NAME@/$LEGACY_DTB_NAME/g" \
        -i $INSTALL/usr/share/bootloader/update.sh
  fi

  # canupdate.sh
  if find_file_path bootloader/canupdate.sh; then
    cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
  fi

  # subdevices
  for PKG_SUBDEVICE in $SUBDEVICES; do

    # boot.ini
    if find_file_path bootloader/${PKG_SUBDEVICE}_boot.ini; then
      cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
    fi

    # caminho u-boot
    if [ "$PKG_SUBDEVICE" = "Odroid_C2" ]; then
      PKG_UBOOTBIN="$(get_build_dir u-boot-${PKG_SUBDEVICE})/u-boot.bin"
    else
      PKG_UBOOTBIN="$(get_build_dir u-boot-${PKG_SUBDEVICE})/fip/u-boot.bin.sd.bin"
    fi

    # copiar só se existir
    if [ -f "$PKG_UBOOTBIN" ]; then
      echo "Installing u-boot for $PKG_SUBDEVICE"
      cp -av "$PKG_UBOOTBIN" \
        "$INSTALL/usr/share/bootloader/${PKG_SUBDEVICE}_u-boot"
    else
      echo "WARNING: u-boot não encontrado para $PKG_SUBDEVICE"
    fi

    PKG_CANUPDATE+="|${PKG_SUBDEVICE}*"
  done

  # config.ini
  if find_file_path bootloader/config.ini; then
    cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
  fi

  # sed seguro
  if [ -f $INSTALL/usr/share/bootloader/canupdate.sh ]; then
    sed -e "s/@PROJECT@/${PKG_CANUPDATE}/g" \
        -i $INSTALL/usr/share/bootloader/canupdate.sh
  fi

  # splash (não quebra build)
  find_file_path splash/boot-logo.bmp.gz && \
    cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader || true

  find_file_path splash/boot-logo-1080.bmp.gz && \
    cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader || true

  find_file_path splash/timeout-logo-1080.bmp.gz && \
    cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader || true
}