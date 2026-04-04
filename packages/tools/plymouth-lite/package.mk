# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue
# Copyright (C) 2025-present Team LibreELEC

PKG_NAME="plymouth-lite"
PKG_VERSION="d41ce34de554a1cae3250e6a945822ed12717eb5"
PKG_SHA256="ee914d57ac8e8c9b4ab238dc3dd1d7e461b62896408e55b8ac737b5edaa8eaca"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/sailfishos/plymouth-lite"
PKG_URL="https://github.com/sailfishos/plymouth-lite/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_INIT="toolchain gcc:init libpng"
PKG_LONGDESC="Boot splash screen based on Fedora's Plymouth code"

# 🔥 necessário manter (sem isso quebra build)
PKG_CONFIGURE_SCRIPT="no"

pre_configure_init() {
  # não suporta build em subdir
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}-init
}

make_target() {
  make CC="${CC}" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
}

# -------- SYSTEM --------
makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -av ply-image ${INSTALL}/usr/bin
}

# -------- INITRAMFS --------
makeinstall_init() {
  mkdir -p ${INSTALL}/usr/bin
  cp -av ply-image ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/splash

  # prioridade para sua imagem custom
  if find_file_path "splash/splash-1080.png"; then
    cp -av ${FOUND_PATH} ${INSTALL}/splash/splash-1080.png

  elif find_file_path "splash/splash-*.png"; then
    cp -av ${FOUND_PATH} ${INSTALL}/splash/
  fi

  # config opcional (novo upstream)
  if find_file_path "splash/splash.conf"; then
    cp -av ${FOUND_PATH} ${INSTALL}/splash/
  fi
}
