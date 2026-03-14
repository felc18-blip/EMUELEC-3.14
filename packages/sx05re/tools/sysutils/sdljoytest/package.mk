# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert
# Copyright (C) 2023 JELOS

PKG_NAME="sdljoytest"
PKG_VERSION="811d9875e0c13e0c87d93351e69169bf74d28270"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/Wintermute0110/sdljoytest"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_LONGDESC="Test joystick with SDL2 in Linux"
PKG_TOOLCHAIN="make"

pre_configure_target() {
  # Corrigir compilador C++ no Makefile
  sed -i "s|gcc|g++|g" Makefile
}

pre_make_target() {
  export CC="${TARGET_CC}"
  export CXX="${TARGET_CXX}"
}

make_target() {
  make CC="${TARGET_CC}" CXX="${TARGET_CXX}"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin

  cp test_gamepad_SDL2 ${INSTALL}/usr/bin/
  ln -sf test_gamepad_SDL2 ${INSTALL}/usr/bin/sdljoytest

  cp map_gamepad_SDL2 ${INSTALL}/usr/bin/
  ln -sf map_gamepad_SDL2 ${INSTALL}/usr/bin/sdljoymap
}
