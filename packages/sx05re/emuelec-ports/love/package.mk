# SPDX-License-Identifier: GPL-2.0-or-later
# LÖVE 11.5 com OpenGL ES nativo — para Amlogic Mali 450/Utgard

PKG_NAME="love"
PKG_VERSION="11.5"
PKG_SHA256="066e0843f71aa9fd28b8eaf27d41abb74bfaef7556153ac2e3cf08eafc874c39"
PKG_LICENSE="Zlib"
PKG_SITE="https://love2d.org"
PKG_URL="https://github.com/love2d/love/releases/download/${PKG_VERSION}/love-${PKG_VERSION}-linux-src.tar.gz"
PKG_ARCH="aarch64"
PKG_PRIORITY="optional"
PKG_SECTION="tools"
PKG_SHORTDESC="LÖVE 11.5 (OpenGL ES nativo)"
PKG_LONGDESC="LÖVE 2D framework buildado com --enable-gles2 para falar GLES 2.0 direto com o driver Mali, sem gl4es."
PKG_TOOLCHAIN="autotools"

PKG_DEPENDS_TARGET="toolchain SDL2 luajit openal-soft libvorbis libmodplug freetype harfbuzz libpng zlib"

PKG_CONFIGURE_OPTS_TARGET=" \
  --prefix=/usr \
  --enable-gles2 \
  --with-lua=luajit \
  --disable-mpg123 \
  --disable-theora \
  --disable-static \
  --enable-shared"

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/share/man
  rm -rf ${INSTALL}/usr/share/pixmaps
  rm -rf ${INSTALL}/usr/share/applications
  rm -rf ${INSTALL}/usr/share/icons
  rm -rf ${INSTALL}/usr/share/mime
  rm -f  ${INSTALL}/usr/lib/liblove*.la
}
