# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libusb"
PKG_VERSION="1.0.26"
PKG_SHA256="12ce7a61fc9854d1d2a1ffe095f7b5fac19ddba095c259e6067a46500381b5a5"
PKG_LICENSE="LGPLv2.1"
PKG_SITE="http://libusb.info/"
PKG_URL="https://github.com/libusb/libusb/releases/download/v${PKG_VERSION}/libusb-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain systemd"
PKG_LONGDESC="The libusb project's aim is to create a Library for use by user level applications to USB devices."

PKG_CONFIGURE_OPTS_TARGET="--enable-shared \
            --enable-static \
            --disable-log \
            --disable-debug-log \
            --enable-udev \
            --disable-examples-build"

post_makeinstall_target() {
  echo "--- Sanitizando bibliotecas do libusb (Limpando rastros do PC) ---"
  
  # Varre toda a pasta de instalação do pacote (bibliotecas e headers)
  find ${INSTALL} -type f -exec sh -c '
    # Verifica se é um binário ELF (bibliotecas .so costumam ser DYN)
    if readelf -h "$1" 2>/dev/null | grep -qE "EXEC|DYN"; then
      # Remove RPATH/RUNPATH que aponta para o seu PC
      patchelf --remove-rpath "$1" 2>/dev/null
      
      # Substitui caminhos absolutos (/home/felipe/...) pelo nome puro da lib
      for lib_path in $(readelf -d "$1" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
        lib_name=$(basename "$lib_path")
        echo "  > Corrigindo dependência em $(basename $1): $lib_name"
        patchelf --replace-needed "$lib_path" "$lib_name" "$1" 2>/dev/null
      done
    fi
  ' _ {} \;
}