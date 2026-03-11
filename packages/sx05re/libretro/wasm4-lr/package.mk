PKG_NAME="wasm4-lr"
PKG_VERSION="59107843a639c3fd17e15dfdf7bbe65360f3080e"
PKG_LICENSE="ISC"
PKG_SITE="https://github.com/aduros/wasm4"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_TOOLCHAIN="manual"
GET_HANDLER_SUPPORT="git"

post_unpack() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive
}

make_target() {
  cd runtimes/native
  cmake -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TARGET=wasm4_libretro
  cmake --build build
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp runtimes/native/build/wasm4_libretro.so ${INSTALL}/usr/lib/libretro/
}