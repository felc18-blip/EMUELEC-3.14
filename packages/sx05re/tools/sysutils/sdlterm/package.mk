# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present EmuELEC (https://github.com/EmuELEC)

PKG_NAME="sdlterm"
PKG_VERSION="v1"
PKG_LICENSE="Public Domain"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_ttf"
PKG_SHORTDESC="simple SDL2 program to read output of bash scripts"
PKG_TOOLCHAIN="manual"

make_target() {
  # Adicionamos CXXFLAGS e LDFLAGS para garantir que as otimizações do projeto sejam mantidas
  # E apontamos manualmente para o SDL2 da Toolchain
  ${CXX} ${CXXFLAGS} ${LDFLAGS} sdlterm.cpp -o sdlterm \
    -I${SYSROOT_PREFIX}/usr/include/SDL2 \
    -L${SYSROOT_PREFIX}/usr/lib \
    -lSDL2 -lSDL2_ttf -pthread
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp sdlterm ${INSTALL}/usr/bin
}