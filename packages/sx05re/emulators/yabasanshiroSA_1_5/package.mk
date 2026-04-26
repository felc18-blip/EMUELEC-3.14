# SPDX-License-Identifier: GPL-2.0-or-later
#
# NextOS Elite Edition — yabasanshiroSA_1_5
# Saturn emulator (yabause/yabasanshiro v1.5 - retro_arena standalone port).
#
# Source: felc18-blip/yabasanshiro-1.5-nextos branch nextos-1_5 (fork de
# devmiyax/yabause B2_1_5). 4 fixes do VIDSoft cherry-picked do 1.11.

PKG_NAME="yabasanshiroSA_1_5"
PKG_VERSION="55fd0704d009cee1a4addc6647fb19b654242bff"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/felc18-blip/yabasanshiro-1.5-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos-1_5"
PKG_DEPENDS_TARGET="toolchain SDL2 boost openal-soft ${OPENGLES} zlib libpng"
PKG_LONGDESC="Yabasanshiro v1.5 — Sega Saturn emulator (NextOS Mali-450 port)"
PKG_TOOLCHAIN="cmake-make"
PKG_SECTION="emuelec/emulators"
PKG_BUILD_FLAGS="+speed"

# Amlogic-old (Mali-450 GLES 2.0, Cortex-A53). Mesmas quirks da 1.11.
# -fno-strict-aliasing CRITICO: GCC15 strict-aliasing UB drops putpixel
# writes em vidsoft.c (back_nonzero=0 mesmo com 10M+ wrote count).
if [ "${DEVICE}" = "Amlogic-old" ]; then
  TARGET_CFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
  TARGET_CXXFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
  TARGET_CFLAGS+=" -fno-strict-aliasing -fno-tree-vectorize -fno-tree-loop-vectorize"
  TARGET_CXXFLAGS+=" -fno-strict-aliasing -fno-tree-vectorize -fno-tree-loop-vectorize"
fi

post_unpack() {
  # m68kmake e bin2c rodam no host durante o build; force que os binarios
  # gerados aqui sejam usados em vez do que CMake tentaria cross-compilar.
  sed -i "s|COMMAND m68kmake|COMMAND ${PKG_BUILD}/m68kmake_host|" ${PKG_BUILD}/yabause/src/musashi/CMakeLists.txt
  sed -i "s|COMMAND ./bin2c|COMMAND ${PKG_BUILD}/bin2c_host|" ${PKG_BUILD}/yabause/src/retro_arena/nanogui-sdl/CMakeLists.txt
}

pre_make_target() {
  $HOST_CC ${PKG_BUILD}/yabause/src/retro_arena/nanogui-sdl/resources/bin2c.c -o ${PKG_BUILD}/bin2c_host
  $HOST_CC ${PKG_BUILD}/yabause/src/musashi/m68kmake.c -o ${PKG_BUILD}/m68kmake_host

  # ExternalProject sub-builds (m68kmake, libchdr) usam CMakeLists.txt
  # legados que declaram cmake_minimum_required < 3.5. CMake 4.x rejeita.
  # CMAKE_POLICY_VERSION_MINIMUM no env var se propaga.
  export CMAKE_POLICY_VERSION_MINIMUM=3.5
}

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="${PKG_BUILD}/yabause \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DYAB_PORTS=retro_arena \
    -DYAB_WANT_DYNAREC_DEVMIYAX=ON \
    -DYAB_WANT_ARM7=ON \
    -DYAB_WANT_VULKAN=OFF \
    -DCMAKE_TOOLCHAIN_FILE=${PKG_BUILD}/yabause/src/retro_arena/n2.cmake \
    -DOPENGL_INCLUDE_DIR=${SYSROOT_PREFIX}/usr/include \
    -DOPENGL_opengl_LIBRARY=${SYSROOT_PREFIX}/usr/lib \
    -DOPENGL_glx_LIBRARY=${SYSROOT_PREFIX}/usr/lib \
    -DLIBPNG_LIB_DIR=${SYSROOT_PREFIX}/usr/lib \
    -Dpng_STATIC_LIBRARIES=${SYSROOT_PREFIX}/usr/lib/libpng16.a"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -a ${PKG_BUILD}/src/retro_arena/yabasanshiro ${INSTALL}/usr/bin/yabasanshiro1_5
  cp -a ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/yabasanshiro1_5
  cp ${PKG_DIR}/config/* ${INSTALL}/usr/config/emuelec/configs/yabasanshiro1_5
}
