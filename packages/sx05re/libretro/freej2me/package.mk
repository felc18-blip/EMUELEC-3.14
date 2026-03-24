# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="freej2me"
PKG_VERSION="09cb30145683cddd370e8b351c6100c1c5f0e744"
PKG_ARCH="any"

PKG_SITE="https://github.com/TASEmulators/freej2me-plus"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain apache-ant:host libXtst"
PKG_SECTION="libretro"
PKG_SHORTDESC="FreeJ2ME Libretro"

PKG_TOOLCHAIN="make"

pre_configure_target() {
  ${TOOLCHAIN}/bin/ant
}

make_target() {
  make -C ${PKG_BUILD}/src/libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/src/libretro/freej2me_libretro.so \
     ${INSTALL}/usr/lib/libretro/

  # jar necessário pro core funcionar
  mkdir -p ${INSTALL}/usr/lib/libretro/freej2me
  cp ${PKG_BUILD}/build/freej2me-lr.jar \
     ${INSTALL}/usr/lib/libretro/freej2me/

  # script opcional
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/freej2me.sh ${INSTALL}/usr/bin/
  chmod 0755 ${INSTALL}/usr/bin/freej2me.sh
}
