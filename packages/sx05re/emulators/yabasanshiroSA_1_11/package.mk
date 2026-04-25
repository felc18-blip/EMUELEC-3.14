# SPDX-License-Identifier: GPL-2.0-or-later
#
# NextOS Elite Edition — yabasanshiroSA_1_11
# Saturn emulator (yabause/yabasanshiro v1.11 - retro_arena standalone port).
#
# Source: felc18-blip/yabasanshiro-1.11-nextos branch nextos-gles2 (fork de
# sydarn/yabause). Mesmas adaptações do 1.5 cherry-picked.

PKG_NAME="yabasanshiroSA_1_11"
PKG_VERSION="12da1ad1bff43151a01d7110261df5df3eebb9a0"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/felc18-blip/yabasanshiro-1.11-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos-gles2"
PKG_DEPENDS_TARGET="toolchain SDL2 boost openal-soft ${OPENGLES} zlib libpng"
PKG_LONGDESC="Yabasanshiro v1.11 — Sega Saturn emulator (NextOS Mali-450 port)"
PKG_TOOLCHAIN="cmake-make"
PKG_SECTION="emuelec/emulators"
PKG_BUILD_FLAGS="+speed"

if [ "${DEVICE}" = "Amlogic-old" ]; then
  TARGET_CFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
  TARGET_CXXFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
  # NextOS GCC15 vidsoft repro: putpixel writes parecem virar no-op com -O3
  # + strict aliasing. Desabilita aliasing UB exploit + vetorizacao no path
  # de rendering pra testar se eh issue de optimization.
  TARGET_CFLAGS+=" -fno-strict-aliasing -fno-tree-vectorize -fno-tree-loop-vectorize"
  TARGET_CXXFLAGS+=" -fno-strict-aliasing -fno-tree-vectorize -fno-tree-loop-vectorize"
fi

post_unpack() {
  sed -i "s|COMMAND m68kmake|COMMAND ${PKG_BUILD}/m68kmake_host|" ${PKG_BUILD}/yabause/src/musashi/CMakeLists.txt
  sed -i "s|COMMAND ./bin2c|COMMAND ${PKG_BUILD}/bin2c_host|" ${PKG_BUILD}/yabause/src/retro_arena/nanogui-sdl/CMakeLists.txt
  # NextOS: ArchR pattern — bump every cmake_minimum_required to 3.5 in
  # all sub-CMakeLists so CMake 4 doesn't reject ancient submodules.
  find ${PKG_BUILD} -type f -name "CMakeLists.txt" -exec sed -i 's/^\s*cmake_minimum_required.*$/cmake_minimum_required(VERSION 3.5)/' {} +
}

pre_make_target() {
  ${HOST_CC} ${PKG_BUILD}/yabause/src/retro_arena/nanogui-sdl/resources/bin2c.c -o ${PKG_BUILD}/bin2c_host
  ${HOST_CC} ${PKG_BUILD}/yabause/src/musashi/m68kmake.c -o ${PKG_BUILD}/m68kmake_host
  export CMAKE_POLICY_VERSION_MINIMUM=3.5
}

pre_configure_target() {
  # NextOS baseline: VIDSoft + GLES2 direto (Mali-450). gl4es+VIDOGL ficou
  # bloqueado por shaders GLSL 330 sem path realista de conversao p/ GLES100.
  # CMAKE_SYSTEM_PROCESSOR=x86_64 dodges the aarch64-specific SH2_DYNAREC=0
  # path so the SH2 cycle counter behaves.
  PKG_CMAKE_OPTS_TARGET="${PKG_BUILD}/yabause \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_PROJECT_INCLUDE=${PKG_BUILD}/yabause/src/retro_arena/n2.cmake \
    -DCMAKE_SYSTEM_PROCESSOR=x86_64 \
    -DYAB_PORTS=retro_arena \
    -DYAB_WANT_DYNAREC_DEVMIYAX=ON \
    -DYAB_WANT_ARM7=ON \
    -DYAB_WANT_VULKAN=OFF \
    -DUSE_EGL=ON \
    -DUSE_OPENGL=OFF \
    -DOPENGL_INCLUDE_DIR=${SYSROOT_PREFIX}/usr/include \
    -DOPENGL_opengl_LIBRARY=${SYSROOT_PREFIX}/usr/lib \
    -DOPENGL_glx_LIBRARY=${SYSROOT_PREFIX}/usr/lib \
    -DLIBPNG_LIB_DIR=${SYSROOT_PREFIX}/usr/lib \
    -Dpng_STATIC_LIBRARIES=${SYSROOT_PREFIX}/usr/lib/libpng16.so"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -a ${PKG_BUILD}/src/retro_arena/yabasanshiro ${INSTALL}/usr/bin/yabasanshiro1_11
  cp -a ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/yabasanshiro1_11
  cp ${PKG_DIR}/config/* ${INSTALL}/usr/config/emuelec/configs/yabasanshiro1_11
}
