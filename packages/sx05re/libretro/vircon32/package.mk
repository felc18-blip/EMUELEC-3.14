# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="vircon32"
PKG_VERSION="99d81d98d153006c99ee8b7243171baba70d28f8"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/vircon32/vircon32-libretro"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_LONGDESC="Vircon32 32-bit Virtual Console"
PKG_TOOLCHAIN="cmake-make"
PKG_AUTORECONF="no"

PKG_LIBNAME="vircon32_libretro.so"
PKG_LIBVAR="VIRCON32_LIB"

PKG_CMAKE_OPTS_TARGET="-DENABLE_OPENGLES3=1 \
                       -DOpenGL_GL_PREFERENCE=GLVND \
                       -DOPENGL_INCLUDE_DIR=${SYSROOT_PREFIX}/usr/include \
                       -DOPENGL_opengl_LIBRARY=${SYSROOT_PREFIX}/usr/lib/libOpenGL.so \
                       -DOPENGL_glx_LIBRARY=${SYSROOT_PREFIX}/usr/lib/libGLX.so"

pre_configure_target() {
  # Patch CMakeLists.txt to make OpenGL optional/mock it for GLES builds
  sed -i 's/find_package(OpenGL REQUIRED)/find_package(OpenGL)/' ${PKG_BUILD}/CMakeLists.txt
  
  # Set OpenGL as found even if desktop OpenGL isn't available
  echo "set(OPENGL_FOUND TRUE)" >> ${PKG_BUILD}/CMakeLists.txt
  echo "set(OPENGL_LIBRARIES \"\")" >> ${PKG_BUILD}/CMakeLists.txt
  
  # Remove static linking flags that cause issues
  sed -i 's/-static-libgcc -static-libstdc++//' ${PKG_BUILD}/CMakeLists.txt
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp -v ${PKG_BUILD}/.${TARGET_NAME}/vircon32_libretro.so ${INSTALL}/usr/lib/libretro/
}