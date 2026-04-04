# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="flycast"
PKG_VERSION="bf2bd7efed41e9f3367a764c2d90fcaa9c38a1f9"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/flyinghead/flycast"
PKG_URL="${PKG_SITE}.git"

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

pre_configure_target() {
  cd ${PKG_BUILD}

  # 🔥 ESSENCIAL → baixa dependências internas
  git submodule update --init --recursive

  # 🔥 FIX GCC 15 (isystem)
  find . -name flags.make -exec sed -i 's:isystem :I:g' {} \; 2>/dev/null
  find . -name build.ninja -exec sed -i 's:isystem :I:g' {} \; 2>/dev/null
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro

  if [ "${ARCH}" = "arm" ]; then
    cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/flycast_32b_libretro.so
  else
    cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/
  fi
}
