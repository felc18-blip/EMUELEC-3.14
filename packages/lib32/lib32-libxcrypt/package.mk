# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="lib32-libxcrypt"
PKG_VERSION="4.4.36"
PKG_SHA256="e5e1f4caee0a01de2aee26e3138807d6d3ca2b8e67287966d1fefd65e1fd8943"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/besser82/libxcrypt"
PKG_URL="https://github.com/besser82/libxcrypt/releases/download/v${PKG_VERSION}/libxcrypt-${PKG_VERSION}.tar.xz"

PKG_DEPENDS_TARGET="lib32-toolchain"
PKG_LONGDESC="libxcrypt provides modern crypt() replacement"

PKG_CONFIGURE_OPTS_TARGET="--host=${LIB32_TARGET_NAME} \
                           --build=${HOST_NAME} \
                           --prefix=/usr \
                           --libdir=/usr/lib32 \
                           --enable-shared \
                           --disable-static"

makeinstall_target() {

  mkdir -p ${INSTALL}/usr/lib32
  mkdir -p ${SYSROOT_PREFIX}/usr/lib
  mkdir -p ${SYSROOT_PREFIX}/usr/include

  # instalar biblioteca no sistema final
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/.libs/libcrypt.so* ${INSTALL}/usr/lib32/

  # instalar biblioteca no sysroot (para linker)
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/.libs/libcrypt.so* ${SYSROOT_PREFIX}/usr/lib/

  # instalar header no sysroot (para compilador)
  cp -v ${PKG_BUILD}/.${TARGET_NAME}/crypt.h ${SYSROOT_PREFIX}/usr/include/

  # garantir symlink padrão para -lcrypt
  ln -sf libcrypt.so.1 ${SYSROOT_PREFIX}/usr/lib/libcrypt.so
}



