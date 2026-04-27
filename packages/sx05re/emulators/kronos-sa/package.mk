# SPDX-License-Identifier: GPL-2.0-or-later
#
# NextOS Elite Edition — kronos-sa
# Sega Saturn / ST-V emulator (Kronos, FCare fork de yabause).
#
# Source: felc18-blip/kronos-nextos (fork de FCare/Kronos pin
# ff8b757e2 — último commit com VIDSoft renderer presente, 1 commit
# antes do mass rework a9aa4478b "Clean useless functions" que
# removeu vidsoft.c). Branch nextos contém os patches necessários
# pra Mali-450 / GLES2 como commits propriamente reviewable.

PKG_NAME="kronos-sa"
PKG_VERSION="e74b8a7136926125620b91708a315bb2a3e8c64c"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/felc18-blip/kronos-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos"
PKG_DEPENDS_TARGET="toolchain SDL2 boost openal-soft zlib qt-everywhere ${OPENGLES}"
PKG_LONGDESC="Kronos — Sega Saturn / ST-V emulator (NextOS Mali-450 port, VIDSoft + Qt5/eglfs/GLES2)"
PKG_TOOLCHAIN="cmake-make"
PKG_SECTION="emuelec/emulators"
PKG_BUILD_FLAGS="+speed"
GET_HANDLER_SUPPORT="git"

if [ "${DEVICE}" = "Amlogic-old" ]; then
  TARGET_CFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mcpu=cortex-a53 -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
  TARGET_CXXFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mcpu=cortex-a53 -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
  # Repro yabasanshiro 1.11: GCC15 + -O3 + strict-aliasing zera writes do
  # putpixel no VIDSoft (fix documentado em feedback_yabasanshiro_111_vidsoft_fix).
  TARGET_CFLAGS+=" -fno-strict-aliasing -fno-tree-vectorize -fno-tree-loop-vectorize"
  TARGET_CXXFLAGS+=" -fno-strict-aliasing -fno-tree-vectorize -fno-tree-loop-vectorize"
  # HAVE_LIBGL: força YabauseGL.cpp como QOpenGLWidget (Qt MOC ignora -D
  # do compiler, mas já hard-coded no fork — flag aqui é defensiva).
  # NEXTOS_GLES2: ativa branch GLES2 em ygl.h (no fork).
  # GL_GLEXT_PROTOTYPES: declara funcs OES (glGenVertexArraysOES etc).
  TARGET_CFLAGS+=" -DHAVE_LIBGL=1 -DNEXTOS_GLES2 -DGL_GLEXT_PROTOTYPES=1"
  TARGET_CXXFLAGS+=" -DHAVE_LIBGL=1 -DNEXTOS_GLES2 -DGL_GLEXT_PROTOTYPES=1"
fi

post_unpack() {
  # m68kmake: cmake builda como aarch64 (target) e tenta executar (host
  # x86_64) → Error 126. Patchamos COMMAND para um m68kmake_host build
  # no pre_make. Esse path é build-env-specific (PKG_BUILD), por isso
  # fica fora do fork.
  M68K_DIR="${PKG_BUILD}/yabause/src/musashi"
  if [ -f "${M68K_DIR}/CMakeLists.txt" ]; then
    sed -i "s|COMMAND m68kmake|COMMAND ${PKG_BUILD}/m68kmake_host|" \
      "${M68K_DIR}/CMakeLists.txt"
  fi

  # -O3/-O2 → -Ofast (otimização extra)
  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/yabause/src/CMakeLists.txt 2>/dev/null || true
}

pre_make_target() {
  ${HOST_CC} ${PKG_BUILD}/yabause/src/musashi/m68kmake.c -o ${PKG_BUILD}/m68kmake_host
  export CMAKE_POLICY_VERSION_MINIMUM=3.5
}

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="${PKG_BUILD}/yabause \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DYAB_USE_QT5=ON \
    -DYAB_WANT_OPENGL=OFF \
    -DYAB_WANT_VULKAN=OFF \
    -DYAB_WANT_SOFT_RENDERING=ON \
    -DYAB_PORTS=qt \
    -DYAB_WANT_DYNAREC_DEVMIYAX=OFF \
    -DYAB_WANT_DYNAREC_KRONOS=ON \
    -DYAB_WANT_ARM7=ON"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin ${INSTALL}/usr/lib
  cp -a ${PKG_BUILD}/src/qt/kronos ${INSTALL}/usr/bin/kronos
  # LD_PRELOAD shim — start_kronos.sh espera em /usr/lib/
  cp -a ${PKG_BUILD}/src/qt/libkronos-eglshim.so ${INSTALL}/usr/lib/
  cp -a ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/start_kronos.sh

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/kronos/qt
  cp ${PKG_DIR}/config/kronos.ini ${INSTALL}/usr/config/emuelec/configs/kronos/qt/
}
