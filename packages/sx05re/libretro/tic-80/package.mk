# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert

PKG_NAME="tic-80"
PKG_VERSION="7020500a6e88f6ee91301933bb77f082a10e10f5"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/nesbox/TIC-80"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="TIC-80 is a fantasy computer for making, playing and sharing tiny games."
GET_HANDLER_SUPPORT="git"

post_unpack() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive
}

pre_configure_target() {
  # 1. 🔥 VACINA REFORÇADA: Adicionamos -fcommon e silenciamos avisos de string
  export CFLAGS="${CFLAGS} -Wno-incompatible-pointer-types -Wno-error=incompatible-pointer-types -fcommon"
  export CXXFLAGS="${CXXFLAGS} -Wno-incompatible-pointer-types -Wno-error=incompatible-pointer-types -fcommon -Wno-write-strings"

  # 2. 🔥 CORREÇÃO DE LUAJIT: Garante que ele use o luajit que você já compilou no sistema
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_SYSTEM_LUAJIT=ON"
}

# 🚀 AJUSTE NAS OPÇÕES:
# Mudamos BUILD_WITH_ALL para OFF e ativamos as linguagens manualmente.
# Isso permite DESLIGAR o PocketPy (que deu erro) sem perder o resto.
PKG_CMAKE_OPTS_TARGET="-DBUILD_LIBRETRO=ON \
                       -DBUILD_PLAYER=ON \
                       -DBUILD_SDL=ON \
                       -DUSE_SYSTEM_SDL2=ON \
                       -DBUILD_WITH_LUA=ON \
                       -DBUILD_WITH_FENNEL=ON \
                       -DBUILD_WITH_WREN=ON \
                       -DBUILD_WITH_POCKETPY=OFF \
                       -DBUILD_WITH_JS=ON \
                       -DBUILD_WITH_RUBY=OFF \
                       -DBUILD_WITH_YUE=OFF \
                       -DBUILD_WITH_JANET=OFF \
                       -DCMAKE_BUILD_TYPE=Release \
                       -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                       -DBUILD_STATIC=ON"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  mkdir -p ${INSTALL}/usr/bin

  # 1. Instala o Core Libretro (RetroArch)
  # O caminho build/.aarch64... é mais rápido e limpo que o 'find'
  cp ${PKG_BUILD}/.${TARGET_NAME}/bin/tic80_libretro.so ${INSTALL}/usr/lib/libretro/tic80_libretro.so

  # 2. Instala o executável Standalone (por causa do seu SDL ON)
  if [ -f "${PKG_BUILD}/.${TARGET_NAME}/bin/tic80" ]; then
    cp ${PKG_BUILD}/.${TARGET_NAME}/bin/tic80 ${INSTALL}/usr/bin/tic80
  fi
}
