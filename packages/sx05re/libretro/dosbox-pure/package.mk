# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="dosbox-pure"
PKG_VERSION="b9f8bc681c55301b7430070b1c2057b3744ad480"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/schellingb/dosbox-pure"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A port of DOSBox to libretro"
GET_HANDLER_SUPPORT="git"
PKG_TOOLCHAIN="make"
PKG_PATCH_DIRS+="${DEVICE}"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  ${STRIP} --strip-debug dosbox_pure_libretro.so
  cp dosbox_pure_libretro.so ${INSTALL}/usr/lib/libretro/
}

