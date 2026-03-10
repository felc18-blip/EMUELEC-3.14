# SPDX-License-Identifier: GPL-2.0
# Based on JELOS

PKG_NAME="tic-80"
PKG_VERSION="8f7f36d2db99748bef8c65ee48657937ce4764cc"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/nesbox/TIC-80"
PKG_URL="${PKG_SITE}.git"

PKG_DEPENDS_TARGET="toolchain zlib"
PKG_SECTION="libretro"
PKG_TOOLCHAIN="cmake"

PKG_GIT_CLONE_SINGLE="no"

PKG_CMAKE_OPTS_TARGET="-DBUILD_LIBRETRO=ON \
-DBUILD_PLAYER=OFF \
-DBUILD_SDL=OFF \
-DBUILD_SDLGPU=OFF \
-DBUILD_SOKOL=OFF \
-DBUILD_TOUCH_INPUT=ON \
-DBUILD_DEMO_CARTS=OFF \
-DBUILD_EDITORS=OFF \
-DBUILD_PRO=OFF \
-DBUILD_STATIC=ON \
-DBUILD_WITH_ZLIB=ON \
-DBUILD_WITH_ALL=OFF \
-DBUILD_WITH_LUA=ON \
-DBUILD_WITH_WREN=OFF \
-DBUILD_WITH_FENNEL=OFF \
-DBUILD_WITH_MRUBY=OFF \
-DBUILD_WITH_JANET=OFF \
-DBUILD_WITH_WASM=OFF \
-DBUILD_WITH_SCHEME=OFF \
-DBUILD_WITH_SQUIRREL=OFF \
-DBUILD_WITH_POCKETPY=OFF \
-DBUILD_WITH_QUICKJS=OFF \
-DBUILD_TOOLS=OFF \
-DCMAKE_BUILD_TYPE=Release"

pre_configure_target() {
  cd ${PKG_BUILD}

  git submodule update --init --recursive || true

  # baixar jsmn manualmente se não existir
  if [ ! -f vendor/jsmn/jsmn.h ]; then
    mkdir -p vendor/jsmn
    curl -L https://raw.githubusercontent.com/zserge/jsmn/master/jsmn.h -o vendor/jsmn/jsmn.h
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/bin/tic80_libretro.so ${INSTALL}/usr/lib/libretro/tic80_libretro.so
}