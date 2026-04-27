# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="gl4es"
PKG_VERSION="9e8037b0c344127993e7d66a17ff42228b0bb806"
PKG_SHA256="d118b691929dac75cdffb1f57e938944c9c419c5f75ecae2ec8b57e82673f04f"
PKG_GIT_CLONE_BRANCH="master"
PKG_SITE="https://github.com/ptitSeb/gl4es"
PKG_LICENSE="GPL"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_LONGDESC=" GL4ES is a OpenGL 2.1/1.5 to GL ES 2.0/1.1 translation library, with support for Pandora, ODroid, OrangePI, CHIP, Raspberry PI, Android, Emscripten and AmigaOS4. "
PKG_TOOLCHAIN="cmake-make"

pre_configure_target() {

if [[ "${DEVICE}" == "Amlogic"* ]]; then
    # NextOS: also build the EGL wrapper (libEGL.so.1) so apps that need
    # fixed-pipeline emulation can LD_PRELOAD it WITHOUT replacing the
    # system /usr/lib/libEGL.so.1 -> libMali.so symlink. We rename the
    # gl4es libEGL to libEGL_gl4es.so.1 (alternative path).
    PKG_CMAKE_OPTS_TARGET=" -DNOX11=1 -DODROID=1 -DGBM=OFF -DEGL_WRAPPER=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
else
    PKG_CMAKE_OPTS_TARGET=" -DNOX11=1 -DODROID=1 -DGBM=ON -DEGL_WRAPPER=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
fi

}

makeinstall_target(){
mkdir -p ${INSTALL}/usr/lib/
cp ${PKG_BUILD}/lib/libGL.so.1 ${INSTALL}/usr/lib/libGL.so
ln -sf libGL.so ${INSTALL}/usr/lib/libGL.so.1
# NextOS: gl4es EGL wrapper as alternative path (NOT replacing Mali libEGL)
if [ -f ${PKG_BUILD}/lib/libEGL.so.1 ]; then
  cp ${PKG_BUILD}/lib/libEGL.so.1 ${INSTALL}/usr/lib/libEGL_gl4es.so.1
fi
}


# If we want to install gl4es to toolchain uncomment the following lines, keep in mind GL will now be available fore the build system and some programs might break, like Scummvm Stand Alone

#  # 1. Instala a biblioteca no Sysroot do Toolchain para que outros pacotes a vejam
#  cp -rf ${INSTALL}/usr/lib/libGL.so ${SYSROOT_PREFIX}/usr/lib/libGL.so
#  ln -sf libGL.so ${SYSROOT_PREFIX}/usr/lib/libGL.so.1
#
# # 2. Copia os headers (essencial para o PPSSPP compilar)
#  mkdir -p ${SYSROOT_PREFIX}/usr/include/GL
#  cp -rf ${PKG_BUILD}/include/* ${SYSROOT_PREFIX}/usr/include/
#
#  # 3. Copia o pkgconfig para o CMake não se perder
#  mkdir -p ${SYSROOT_PREFIX}/usr/lib/pkgconfig
#  cp -rf ${PKG_DIR}/pkgconfig/gl.pc ${SYSROOT_PREFIX}/usr/lib/pkgconfig/
