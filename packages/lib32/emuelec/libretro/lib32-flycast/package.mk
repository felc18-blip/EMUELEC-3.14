# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="lib32-flycast"
PKG_VERSION="$(get_pkg_version flycast)"
PKG_NEED_UNPACK="$(get_pkg_directory flycast)"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/flyinghead/flycast"
PKG_URL=""

PKG_DEPENDS_TARGET="lib32-toolchain lib32-${OPENGLES} lib32-zlib lib32-zstd"
PKG_PATCH_DIRS+=" $(get_pkg_directory flycast)/patches"

PKG_SHORTDESC="Flycast Dreamcast emulator (libretro 32bit)"
PKG_BUILD_FLAGS="lib32 -lto"
PKG_TOOLCHAIN="cmake"

PKG_CFLAGS+=" -DHWCAP2_CRC32=0 -DHWCAP2_SHA1=0 -DHWCAP2_SHA2=0 -DHWCAP2_AES=0"
PKG_CXXFLAGS+=" -DHWCAP2_CRC32=0 -DHWCAP2_SHA1=0 -DHWCAP2_SHA2=0 -DHWCAP2_AES=0"

PKG_CMAKE_OPTS_TARGET="
-DLIBRETRO=ON
-DUSE_OPENMP=OFF
-DUSE_GLES2=OFF
-DUSE_GLES=ON
-DUSE_VULKAN=OFF
-DUSE_DISCORD=OFF
-DUSE_SYSTEM_LIBZIP=OFF
-DBUILD_TESTING=OFF
-DCMAKE_BUILD_TYPE=Release
"

unpack() {
  ${SCRIPTS}/get flycast
  mkdir -p ${PKG_BUILD}
  tar cf - -C ${SOURCES}/flycast/flycast-${PKG_VERSION} ${PKG_TAR_COPY_OPTS} . | tar xf - -C ${PKG_BUILD}
}

pre_configure_target() {
  cd ${PKG_BUILD}

  git init
  git submodule update --init --recursive core/deps/libchdr
  git submodule update --init --recursive core/deps/asio

  CPUARCH="core/deps/libchdr/deps/lzma-24.05/src/CpuArch.c"

  if [ -f "$CPUARCH" ]; then
    # garantir que HWCAP2 macros existam
    sed -i '1i\
#ifndef HWCAP2_CRC32\n#define HWCAP2_CRC32 0\n#endif\n#ifndef HWCAP2_SHA1\n#define HWCAP2_SHA1 0\n#endif\n#ifndef HWCAP2_SHA2\n#define HWCAP2_SHA2 0\n#endif\n#ifndef HWCAP2_AES\n#define HWCAP2_AES 0\n#endif\n' "$CPUARCH"
  fi

  find ${PKG_BUILD} -name flags.make -exec sed -i 's:isystem :I:g' {} \; 2>/dev/null
  find ${PKG_BUILD} -name build.ninja -exec sed -i 's:isystem :I:g' {} \; 2>/dev/null
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/flycast_32b_libretro.so
}