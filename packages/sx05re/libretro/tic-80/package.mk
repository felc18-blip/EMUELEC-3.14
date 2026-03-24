# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert

PKG_NAME="tic-80"
PKG_VERSION="a2c875f7275541e7724199ce8e504fb578b819a6"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/nesbox/TIC-80"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_GIT_RECURSIVE="yes"
PKG_LONGDESC="TIC-80 is a fantasy computer for making, playing and sharing tiny games."
GET_HANDLER_SUPPORT="git"

PKG_CMAKE_OPTS_TARGET="-DBUILD_LIBRETRO=ON \
                       -DBUILD_PLAYER=ON \
                       -DBUILD_SDL=ON \
                       -DUSE_SYSTEM_SDL2=ON \
                       -DBUILD_WITH_RUBY=OFF \
                       -DBUILD_WITH_YUE=OFF \
                       -DCMAKE_BUILD_TYPE=Release \
                       -DBUILD_WITH_JANET=OFF \
                       -DBUILD_WITH_ALL=ON \
                       -DBUILD_STATIC=ON"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  # Procura o arquivo .so e copia para a pasta de cores
  find ${PKG_BUILD} -name "tic80_libretro.so" -exec cp {} ${INSTALL}/usr/lib/libretro/tic80_libretro.so \;
}