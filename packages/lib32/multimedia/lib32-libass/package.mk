# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-2022 Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-libass"
PKG_VERSION="$(get_pkg_version libass)"
PKG_LICENSE="BSD"
PKG_SITE="https://github.com/libass/libass"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-freetype lib32-fontconfig lib32-fribidi lib32-harfbuzz"
PKG_LONGDESC="Versão 32-bits do renderizador de legendas ASS/SSA para multilib."

# 🔥 Força o uso do autotools para evitar que o sistema tente usar Meson
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="lib32"

# Sincroniza patches com a versão de 64-bits
PKG_PATCH_DIRS+=" $(get_pkg_directory libass)/patches"

# Removi o --host manual, o sistema já injeta o correto (armv8a-emuelec-linux-gnueabihf)
PKG_CONFIGURE_OPTS_TARGET="--disable-test \
                           --enable-fontconfig \
                           --disable-libunibreak \
                           --disable-silent-rules \
                           --with-pic \
                           --with-gnu-ld"

unpack() {
  # Busca o pacote original
  ${SCRIPTS}/get libass
  mkdir -p ${PKG_BUILD}
  # Extrai usando a versão detectada do pacote pai
  tar --strip-components=1 -xf ${SOURCES}/libass/libass-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

post_configure_target() {
  libtool_remove_rpath libtool
}

post_makeinstall_target() {
  # Limpeza multilib: Remove arquivos que já existem na versão 64-bits
  rm -rf ${INSTALL}/usr/include
  rm -rf ${INSTALL}/usr/share
  rm -rf ${INSTALL}/usr/bin

  # Move bibliotecas para a pasta de 32-bits
  if [ -d "${INSTALL}/usr/lib" ]; then
    mkdir -p ${INSTALL}/usr/lib32
    mv ${INSTALL}/usr/lib/* ${INSTALL}/usr/lib32/
    rm -rf ${INSTALL}/usr/lib
  fi
}
