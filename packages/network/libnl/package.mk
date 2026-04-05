# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libnl"
PKG_VERSION="3.12.0"
PKG_SHA256="fc51ca7196f1a3f5fdf6ffd3864b50f4f9c02333be28be4eeca057e103c0dd18"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/thom311/libnl"
PKG_URL="https://github.com/thom311/libnl/releases/download/libnl${PKG_VERSION//./_}/libnl-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A library for applications dealing with netlink socket - NextOS Elite (Kernel 3.14 Fix)."
PKG_BUILD_FLAGS="+pic"
PKG_TOOLCHAIN="autotools"

# Mantendo o padrão EmuELEC: Estático e sem bibliotecas compartilhadas
PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --disable-shared \
                           --disable-cli \
                           --disable-check \
                           --with-pic"

pre_configure_target() {
  # 1. Mocking de Headers (Satisfaz o #include sem precisar do Kernel novo)
  mkdir -p ${PKG_BUILD}/include/linux
  touch ${PKG_BUILD}/include/linux/ila.h
  # 2. Stubbing de Módulos (Garante que o Makefile não quebre por falta de símbolos)
  echo "/* NextOS Elite: ILA bypass for Kernel 3.14 */" > ${PKG_BUILD}/lib/route/nh_encap_ila.c
  # 3. Injeção de Flags
  export CFLAGS="${TARGET_CFLAGS} -I${PKG_BUILD}/include"

  # 4. Cleanup de segurança
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}
}
