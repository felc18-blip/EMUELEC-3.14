# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present NextOS (felc18-blip)
# Originally adapted from ArchR (https://github.com/archr-linux/Arch-R)

PKG_NAME="daedalusx64-sa"
PKG_VERSION="832bd3d74bb21fc100180c91dc21e7ef13c9f80f"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/felc18-blip/daedalusx64-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos-gles2"
PKG_DEPENDS_TARGET="toolchain libfmt SDL2 SDL2_ttf glm ${OPENGLES}"
PKG_LONGDESC="DaedalusX64 — N64 emulator (NextOS Amlogic-old, native GLES2 port)"
PKG_TOOLCHAIN="cmake-make"
PKG_PATCH_DIRS+=" ${DEVICE}"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET=" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DDAEDALUS_GL=OFF \
    -DDAEDALUS_GLES=ON \
    -DDAEDALUS_SDL=ON \
    -DDAEDALUS_POSIX=ON \
    -DDAEDALUS_DEBUG_CONSOLE=OFF \
    -DDAEDALUS_LOG=OFF \
    -DDAEDALUS_SILENT=ON \
    -DDAEDALUS_ENABLE_DYNAREC=OFF"

  export CFLAGS="${CFLAGS} -Wno-error -fcommon -DGL_GLEXT_PROTOTYPES"
  export CXXFLAGS="${CXXFLAGS} -Wno-error -fcommon -Wno-template-body -DGL_GLEXT_PROTOTYPES"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/config/DaedalusX64
  cp ${PKG_BUILD}/.${TARGET_NAME}/Source/daedalus ${INSTALL}/usr/config/DaedalusX64/daedalus
  cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  cp ${PKG_DIR}/config/* ${INSTALL}/usr/config/DaedalusX64
  cp -r ${PKG_BUILD}/Data/* ${INSTALL}/usr/config/DaedalusX64
  cp -r ${PKG_BUILD}/Source/SysGLES/HLEGraphics/n64.psh ${INSTALL}/usr/config/DaedalusX64 2>/dev/null || \
    cp -r ${PKG_BUILD}/Source/SysGL/HLEGraphics/n64.psh ${INSTALL}/usr/config/DaedalusX64
  chmod +x ${INSTALL}/usr/bin/*
}
