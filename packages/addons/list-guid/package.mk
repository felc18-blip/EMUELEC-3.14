# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ArchR (https://github.com/archr-linux/Arch-R)

PKG_NAME="list-guid"
PKG_VERSION="ea44ab254d09d2d86eeb70289673418df2beee75"
PKG_LICENSE="GPLv2"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_LONGDESC="Simple SDL tool to create a list off GUIDs for all connected gamepads."
PKG_TOOLCHAIN="make"

pre_make_target() {
  cp -f ${PKG_DIR}/Makefile ${PKG_BUILD}
  cp -f ${PKG_DIR}/list-guid.cpp ${PKG_BUILD}

  SDL2_CFLAGS="$(${TOOLCHAIN}/bin/pkg-config --cflags sdl2)"
  SDL2_LIBS="$(${TOOLCHAIN}/bin/pkg-config --libs sdl2)"

  CFLAGS+=" ${SDL2_CFLAGS}"
  CXXFLAGS+=" ${SDL2_CFLAGS}"
  LDFLAGS+=" ${SDL2_LIBS}"

  sed -i "s|-I\$(get_build_dir SDL2)/include|${SDL2_CFLAGS}|g" ${PKG_BUILD}/Makefile 2>/dev/null || true

  sed -i "s|#include <SDL.h>|#include <SDL2/SDL.h>|g" ${PKG_BUILD}/list-guid.cpp
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/list-guid ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/*
}
