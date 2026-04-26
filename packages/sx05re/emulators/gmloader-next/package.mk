# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present NextOS Elite Edition
#
# gmloader-next: compatibility layer for Android GameMaker runner
# (libyoyo.so) on ARM Linux. Successor of droidports/gmloader, supports
# GMS 2.2.1+ with improved ELF loader and JNI thunks.
#
# NextOS notes (Mali-450 / Amlogic-old aarch64):
# - Binary loads libGLESv2/libEGL via dlopen at runtime — no GLES link.
#   GMS games that request EGL_OPENGL_ES2_BIT run; games requiring
#   EGL_OPENGL_ES3_BIT fail at context creation (HW limit, not loader).
# - Output named gmloadernext.aarch64 to match PortMaster .port script
#   convention; ports look up this exact filename.

PKG_NAME="gmloader-next"
PKG_VERSION="c2fca354df73761887c15f44a0b28ec823581cd5"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL-3.0"
PKG_SITE="https://github.com/JohnnyonFlame/gmloader-next"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="master"
GET_HANDLER_SUPPORT="git"
PKG_DEPENDS_TARGET="toolchain SDL2 zlib Python3:host"
PKG_LONGDESC="Compatibility layer for Android GameMaker runtime (libyoyo.so) on Linux ARM. Used by PortMaster GMS-based ports (Plants vs Zombies ND etc)."
PKG_TOOLCHAIN="manual"

make_target() {
  # Cross-compile via NextOS toolchain.
  # Makefile expects ARCH= as the cross-prefix (aarch64-linux-gnu),
  # but NextOS uses aarch64-libreelec-linux-gnu — pass CROSS= explicitly
  # to override and keep DEVICE_ARCH=aarch64 for output naming.
  # LLVM_INC: scripts/generate_libc.py usa libclang pra parsear glibc headers
  # do target. Aponta pros includes builtins do GCC + sysroot do toolchain
  # NextOS pra achar stddef.h, stdint.h etc.
  GCC_VER=$(${CC} -dumpversion)
  GCC_BUILTIN_INC="${TOOLCHAIN}/lib/gcc/aarch64-libreelec-linux-gnu/${GCC_VER}/include"
  # PYTHONPATH: clang.cindex bindings nao estao no Python do toolchain;
  # use o user site-packages (instalado via pip --user clang).
  PYTHONPATH=${HOME}/.local/lib/python3.14/site-packages:${PYTHONPATH} \
  make -f Makefile.gmloader \
    ARCH=aarch64-linux-gnu \
    CROSS=${TARGET_PREFIX} \
    DEVICE_ARCH=aarch64 \
    CC=${CC} \
    CXX=${CXX} \
    LD=${LD} \
    PKG_CONFIG=${PKG_CONFIG_PATH:-pkg-config} \
    LLVM_SYSROOT=${SYSROOT_PREFIX} \
    LLVM_INC="${GCC_BUILTIN_INC} ${SYSROOT_PREFIX}/usr/include" \
    -j$(nproc)
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp build/aarch64-linux-gnu/gmloader/gmloadernext.aarch64 \
     ${INSTALL}/usr/bin/gmloadernext.aarch64
  chmod 0755 ${INSTALL}/usr/bin/gmloadernext.aarch64
}
