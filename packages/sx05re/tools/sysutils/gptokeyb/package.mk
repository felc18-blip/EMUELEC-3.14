# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="gptokeyb"
PKG_VERSION="0303b36b5376a9b25cf82a53ed4242509daf14e9"
PKG_ARCH="any"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/EmuELEC/gptokeyb"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain libevdev SDL2"
PKG_TOOLCHAIN="make"
GET_HANDLER_SUPPORT="git"

pre_configure_target() {

  # corrigir includes do libevdev
  sed -i 's|libevdev-1.0/libevdev/libevdev-uinput.h|libevdev/libevdev-uinput.h|g' gptokeyb.cpp
  sed -i 's|libevdev-1.0/libevdev/libevdev.h|libevdev/libevdev.h|g' gptokeyb.cpp

  # corrigir sdl2-config
  sed -i "s|sdl2-config|${SYSROOT_PREFIX}/usr/bin/sdl2-config|g" Makefile

  # corrigir include path
  sed -i "s|-I/usr/include/libevdev-1.0|-I${SYSROOT_PREFIX}/usr/include/libevdev-1.0|g" Makefile
}

make_target() {
  make CC=${CC} \
       CFLAGS="${CFLAGS}" \
       LDFLAGS="${LDFLAGS}"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp gptokeyb ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/gptokeyb
  cp -rf ${PKG_BUILD}/configs/*.gptk ${INSTALL}/usr/config/emuelec/configs/gptokeyb
}