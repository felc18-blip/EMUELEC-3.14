# SPDX-License-Identifier: GPL-2.0
PKG_NAME="RTL8821CU"
PKG_VERSION="git"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/brektrou/rtl8821CU"
PKG_URL="https://github.com/brektrou/rtl8821CU/archive/refs/heads/master.zip"
PKG_DEPENDS_TARGET="toolchain linux"
PKG_TOOLCHAIN="manual"
PKG_LONGDESC="Realtek RTL8821CU USB WiFi driver"

get_driver_dir() {
  find $PKG_BUILD -maxdepth 1 -type d -iname "rtl8821cu*"
}

pre_make_target() {
  DRIVER_DIR=$(get_driver_dir)

  echo "Driver dir: $DRIVER_DIR"

  if [ -z "$DRIVER_DIR" ]; then
    echo "ERRO: driver dir não encontrado"
    exit 1
  fi

  sed -i 's/-Werror//g' $DRIVER_DIR/Makefile

  sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' $DRIVER_DIR/Makefile
  sed -i 's/CONFIG_PLATFORM_ARM_RPI = y/CONFIG_PLATFORM_ARM_RPI = n/g' $DRIVER_DIR/Makefile
  sed -i 's/CONFIG_PLATFORM_ARM64_RPI = y/CONFIG_PLATFORM_ARM64_RPI = n/g' $DRIVER_DIR/Makefile

  echo "CONFIG_PLATFORM_ARM64_GENERIC = y" >> $DRIVER_DIR/Makefile

  sed -i 's/CONFIG_IOCTL_CFG80211 = y/CONFIG_IOCTL_CFG80211 = n/g' $DRIVER_DIR/Makefile
}

make_target() {
  DRIVER_DIR=$(get_driver_dir)

  cd $DRIVER_DIR

  make \
    ARCH=$TARGET_KERNEL_ARCH \
    CROSS_COMPILE=$TARGET_KERNEL_PREFIX \
    KSRC=$(kernel_path) \
    KVER=$(kernel_version)
}

makeinstall_target() {
  DRIVER_DIR=$(get_driver_dir)

  mkdir -p $INSTALL/usr/lib/modules/$(kernel_version)/kernel/drivers/net/wireless
  cp $DRIVER_DIR/8821cu.ko $INSTALL/usr/lib/modules/$(kernel_version)/kernel/drivers/net/wireless/
}