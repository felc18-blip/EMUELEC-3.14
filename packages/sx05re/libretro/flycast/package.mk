PKG_NAME="flycast"
PKG_VERSION="$(get_pkg_version flycastsa)"
PKG_NEED_UNPACK="$(get_pkg_directory flycastsa)"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/flyinghead/flycast"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_SUBMODULES="yes"

PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_SHORTDESC="Flycast is a multiplatform Sega Dreamcast emulator"
PKG_BUILD_FLAGS="-lto"
PKG_TOOLCHAIN="cmake"

PKG_CMAKE_OPTS_TARGET="-DLIBRETRO=ON \
                       -DUSE_OPENMP=OFF \
                       -DCMAKE_BUILD_TYPE=Release \
                       -DUSE_GLES2=OFF \
                       -DUSE_GLES=ON \
                       -DUSE_VULKAN=OFF"

post_unpack() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive
}

pre_make_target() {
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" {} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" {} \;
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  if [ "${ARCH}" == "arm" ]; then
    cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/flycast_32b_libretro.so
  else
    cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/
  fi
}