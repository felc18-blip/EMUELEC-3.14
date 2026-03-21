# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="lib32-kmod"
PKG_VERSION="$(get_pkg_version kmod)"
PKG_NEED_UNPACK="$(get_pkg_directory kmod)"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain"
SD_DIRECTORY="$(get_pkg_directory kmod)"
PKG_PATCH_DIRS+=" ${SD_DIRECTORY}/patches"
PKG_LONGDESC="kmod (32-bit libs) para compatibilidade com systemd-libs 32-bit."
PKG_BUILD_FLAGS="lib32"
PKG_TOOLCHAIN="autotools"

# Configuração específica para cross-compile 32-bit
PKG_CONFIGURE_OPTS_TARGET="--libdir=/usr/lib \
                           --bindir=/usr/bin \
                           --enable-tools \
                           --enable-shared \
                           --disable-static \
                           --enable-logging \
                           --disable-debug \
                           --disable-manpages \
                           --with-gnu-ld \
                           --without-xz \
                           --without-zlib \
                           --without-zstd"

unpack() {
  # Reutiliza o código fonte do kmod principal (64-bit) para economizar download
  ${SCRIPTS}/get kmod
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/kmod/kmod-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

post_makeinstall_target() {
  # Cria os links simbólicos de compatibilidade dentro do ambiente 32-bit
  mkdir -p ${INSTALL}/usr/sbin
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/lsmod
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/insmod
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/rmmod
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/modinfo
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/modprobe
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/depmod

  mkdir -p ${INSTALL}/etc
    ln -sf /storage/.config/modprobe.d ${INSTALL}/etc/modprobe.d

  # Adiciona diretório modprobe.d do usuário
  mkdir -p ${INSTALL}/usr/config/modprobe.d

  # --- TRATAMENTO LIB32 PARA O SYSROOT ---
  # Isso aqui é o que o seu systemd-libs de 32 bits vai ler:
  mkdir -p ${SYSROOT_PREFIX}/usr/lib/pkgconfig
  cp -P ${INSTALL}/usr/lib/libkmod.so* ${SYSROOT_PREFIX}/usr/lib/
  cp -va ${INSTALL}/usr/lib/pkgconfig/libkmod.pc ${SYSROOT_PREFIX}/usr/lib/pkgconfig/
  
  # Copia o header para o sysroot de 32 bits também
  mkdir -p ${SYSROOT_PREFIX}/usr/include
  cp -va ${INSTALL}/usr/include/libkmod.h ${SYSROOT_PREFIX}/usr/include/
}