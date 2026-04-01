# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="plymouth-lite"
PKG_VERSION="0.6.0"
PKG_SHA256="fa7b581bdd38c5751668243ff9d2ebaee7c45753358cbb310fb50cfcd3a8081b"
PKG_LICENSE="GPL"
PKG_SITE="http://www.meego.com"
PKG_URL="${DISTRO_SRC}/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_INIT="toolchain gcc:init libpng"
PKG_LONGDESC="Boot splash screen based on Fedora's Plymouth code"

# 🔥 O SEGREDO: Impede o erro de 'No targets specified'
PKG_CONFIGURE_SCRIPT="no"

pre_configure_init() {
  # plymouth-lite não suporta build em subdiretórios
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}-init
}

make_target() {
  # Roda o make diretamente usando o compilador do projeto
  make CC="${CC}" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
}

makeinstall_target() {
  # Instala no sistema principal
  mkdir -p ${INSTALL}/usr/bin
  cp -av ply-image ${INSTALL}/usr/bin
}

makeinstall_init() {
  # Instala especificamente no INITRAMFS (Essencial para o NextOS)
  mkdir -p ${INSTALL}/usr/bin
  cp -av ply-image ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/splash

  # Busca e instala a logo (Prioriza a sua customizada)
  if find_file_path "splash/splash-1080.png"; then
    cp -av ${FOUND_PATH} ${INSTALL}/splash/splash-1080.png
  elif find_file_path "splash/splash-*.png"; then
    cp -av ${FOUND_PATH} ${INSTALL}/splash/
  fi
}
