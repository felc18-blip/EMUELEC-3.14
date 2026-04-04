# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="wifi_dummy-aml"
PKG_VERSION="1.0"
PKG_SHA256=""
PKG_LICENSE="GPL"
PKG_SITE="https://coreelec.org"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain linux"
PKG_NEED_UNPACK="$LINUX_DEPENDS"
PKG_LONGDESC="$PKG_NAME: Linux driver"
PKG_IS_KERNEL_PKG="yes"
PKG_TOOLCHAIN="manual"

pre_make_target() {
  unset LDFLAGS
}

make_target() {
  make ARCH=$TARGET_KERNEL_ARCH \
       CROSS_COMPILE=$TARGET_KERNEL_PREFIX \
       EXTRA_CFLAGS="-std=gnu89 -Wno-error" \
       KCFLAGS="-std=gnu89 -Wno-error" \
       HOSTCFLAGS="-std=gnu89" \
       -C "$(kernel_path)" \
       M="$PKG_BUILD"
}

makeinstall_target() {
  mkdir -p $INSTALL/$(get_full_module_dir)/$PKG_NAME
    find $PKG_BUILD/ -name \*.ko -not -path '*/\.*' -exec cp {} $INSTALL/$(get_full_module_dir)/$PKG_NAME \;
}
