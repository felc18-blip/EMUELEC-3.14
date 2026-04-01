# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-2018 Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="device-trees-amlogic"
PKG_VERSION="cdfe64399f04ef958b4bd8ac629026007c9dd900"
PKG_SHA256="f7e01f869d99db1d5d3f6f2002fed77969c5d78abb8cc34b4a4539da801c069c"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/CoreELEC/device-trees-amlogic"
PKG_URL="https://github.com/CoreELEC/device-trees-amlogic/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_DEPENDS_UNPACK="linux"
PKG_LONGDESC="Device trees for Amlogic devices."
PKG_TOOLCHAIN="manual"

# Compila o dtbTool para rodar no PC (Host) usando a GLIBC do seu Ubuntu
make_host() {
  $HOST_CC -Wall $PKG_BUILD/dtbTool.c -o $PKG_BUILD/dtbTool
}

# Instala a ferramenta na pasta de binaríos da toolchain
makeinstall_host() {
  mkdir -p $TOOLCHAIN/bin
  cp $PKG_BUILD/dtbTool $TOOLCHAIN/bin/
}

make_target() {
  export PATH=$TOOLCHAIN/bin:$PATH

  pushd $BUILD/build/linux-$(kernel_version) > /dev/null

  # 🔥 CORREÇÃO AQUI
  kernel_make HOSTLDFLAGS="$HOSTLDFLAGS -Wl,--allow-multiple-definition" olddefconfig

  EXTRA_TREES=( \
                gxbb_p200 gxbb_p200_2G gxbb_p201 gxbb_p200_1G_wetek_hub gxbb_p200_2G_wetek_play_2 \
                gxl_p212_1g gxl_p212_2g gxl_p230_2g gxl_p281_1g gxm_q200_2g gxm_q201_1g gxm_q201_2g \
              )

  for f in ${EXTRA_TREES[@]}; do
    DTB_LIST="$DTB_LIST $f.dtb"
  done

  cp -f $PKG_BUILD/*.dts* arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/

  for f in $PKG_BUILD/*.dts; do
    DTB_NAME="$(basename $f .dts).dtb"
    DTB_LIST="$DTB_LIST $DTB_NAME"
  done

  kernel_make HOSTLDFLAGS="$HOSTLDFLAGS -Wl,--allow-multiple-definition" $DTB_LIST

  cp arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/*.dtb $PKG_BUILD

  popd > /dev/null
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/bootloader/device_trees
  cp -a $PKG_BUILD/*.dtb $INSTALL/usr/share/bootloader/device_trees
}
