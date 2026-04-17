# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="vircon32"
PKG_VERSION="3faedc6c577333eb785a93cec96ad7d484309f3c"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/vircon32/vircon32-libretro"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_LONGDESC="Vircon32 32-bit Virtual Console"
PKG_TOOLCHAIN="cmake-make"

PKG_LIBNAME="vircon32_libretro.so"
PKG_LIBVAR="VIRCON32_LIB"

PKG_CMAKE_OPTS_TARGET="-DENABLE_OPENGLES2=1 \
                         -DPLATFORM=EMUELEC \
                         -DOPENGL_INCLUDE_DIR=${SYSROOT_PREFIX}/usr/include \
                         -DCMAKE_BUILD_TYPE=Release \
                         -DCMAKE_RULE_MESSAGES=OFF \
                         -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"


makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp -v ${PKG_BUILD}/.${TARGET_NAME}/vircon32_libretro.so ${INSTALL}/usr/lib/libretro/
}
