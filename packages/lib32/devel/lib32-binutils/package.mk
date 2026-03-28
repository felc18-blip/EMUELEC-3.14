# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-2022 Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-binutils"
PKG_VERSION="$(get_pkg_version binutils)"
PKG_NEED_UNPACK="$(get_pkg_directory binutils)"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL"
PKG_URL=""
PKG_DEPENDS_HOST="ccache:host bison:host flex:host lib32-linux-headers"
PKG_DEPENDS_TARGET="lib32-toolchain binutils"
PKG_LONGDESC="A GNU collection of binary utilities for multilib ARM."
PKG_PATCH_DIRS+=" $(get_pkg_directory binutils)/patches"

PKG_CONFIGURE_OPTS_HOST="--target=${LIB32_TARGET_NAME} \
                         --with-sysroot=${LIB32_SYSROOT_PREFIX} \
                         --with-lib-path=${LIB32_SYSROOT_PREFIX}/lib:${LIB32_SYSROOT_PREFIX}/usr/lib \
                         --without-ppl \
                         --enable-static \
                         --without-cloog \
                         --disable-werror \
                         --disable-multilib \
                         --disable-libada \
                         --disable-libssp \
                         --enable-version-specific-runtime-libs \
                         --enable-plugins \
                         --enable-gold \
                         --enable-ld=default \
                         --enable-lto \
                         --disable-nls"

unpack() {
  ${SCRIPTS}/get binutils
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/binutils/binutils-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

pre_configure_host() {
  unset CPPFLAGS
  unset CFLAGS
  unset CXXFLAGS
  unset LDFLAGS
}

make_host() {
  make configure-host
  make MAKEINFO=true
}

makeinstall_host() {
  # 1. headers (usar sysroot correto do lib32)
  mkdir -p ${LIB32_SYSROOT_PREFIX}/usr/include
  cp -v ../include/libiberty.h ${LIB32_SYSROOT_PREFIX}/usr/include

  # 2. instalar libsframe no sysroot lib32
  make DESTDIR="${LIB32_SYSROOT_PREFIX}" -C libsframe install

  # 3. garantir que o linker encontre libsframe
  export LDFLAGS="-L${LIB32_SYSROOT_PREFIX}/usr/lib"

  # 4. instalar bfd (depende de libsframe)
  make DESTDIR="${LIB32_SYSROOT_PREFIX}" -C bfd install

  # 5. restante
  make HELP2MAN=true MAKEINFO=true install
}

configure_target() {
  :
}

make_target() {
  :
}

makeinstall_target() {
  mkdir -p ${INSTALL}/etc
    # ln -sf /storage/.cache/ld.so.cache ${INSTALL}/etc/ld.so.cache
    # ln -sf /storage/.cache/ld.so.cache~ ${INSTALL}/etc/ld.so.cache~
    echo "include /etc/ld.so.conf.d/*.conf" > ${INSTALL}/etc/ld.so.conf
  # mkdir -p ${INSTALL}/usr/cache
  #   touch ${INSTALL}/usr/cache/ld.so.cache
  #   touch ${INSTALL}/usr/cache/ld.so.cache~
  mkdir -p ${INSTALL}/usr/lib
    ln -sf ../lib32/ld-linux-armhf.so.3 ${INSTALL}/usr/lib
}
