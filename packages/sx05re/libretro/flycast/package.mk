################################################################################
# Flycast - FIXED PACKAGE (standalone + no submodule issues)
################################################################################

PKG_NAME="flycast"
PKG_VERSION="bf2bd7efed41e9f3367a764c2d90fcaa9c38a1f9"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/flyinghead/flycast"

# 🔥 CLONE CORRETO (com submodules)
PKG_URL="https://github.com/flyinghead/flycast.git"

PKG_DEPENDS_TARGET="toolchain ${OPENGLES} zlib zstd"
PKG_SHORTDESC="Flycast is a multiplatform Sega Dreamcast emulator"
PKG_BUILD_FLAGS="-lto"
PKG_TOOLCHAIN="cmake"

# 🔧 CONFIG LIMPA E COMPATÍVEL (kernel antigo + GLES)
PKG_CMAKE_OPTS_TARGET="-DLIBRETRO=ON \
                      -DUSE_OPENMP=OFF \
                      -DCMAKE_BUILD_TYPE=Release \
                      -DUSE_GLES2=OFF \
                      -DUSE_GLES=ON \
                      -DUSE_VULKAN=OFF \
                      -DUSE_SYSTEM_ZLIB=ON \
                      -DUSE_SYSTEM_ZSTD=ON"

pre_configure_target() {
  # 🔥 garante submodules (caso build system ignore clone opts)
  cd ${PKG_BUILD}
  git submodule update --init --recursive || true
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
