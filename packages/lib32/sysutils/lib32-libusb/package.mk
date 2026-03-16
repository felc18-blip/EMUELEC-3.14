# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-2022 Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-libusb"
PKG_VERSION="$(get_pkg_version libusb)"
PKG_NEED_UNPACK="$(get_pkg_directory libusb)"
PKG_ARCH="aarch64"
PKG_LICENSE="LGPLv2.1"
PKG_SITE="http://libusb.info/"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-systemd-libs"
PKG_PATCH_DIRS+=" $(get_pkg_directory libusb)/patches"
PKG_LONGDESC="The libusb project's aim is to create a Library for use by user level applications to USB devices."
PKG_BUILD_FLAGS="lib32"

PKG_CONFIGURE_OPTS_TARGET="--enable-shared \
            --enable-static \
            --disable-log \
            --disable-debug-log \
            --enable-udev \
            --disable-examples-build"

unpack() {
  ${SCRIPTS}/get libusb
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/libusb/libusb-${PKG_VERSION}.tar.bz2 -C ${PKG_BUILD}
}

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/include
  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32

  # --- INÍCIO DA FAXINA (Focado na pasta lib32) ---
  echo "--- Sanitizando lib32-libusb (Limpando rastros do PC) ---"
  find ${INSTALL}/usr/lib32 -type f -exec sh -c '
    if readelf -h "$1" 2>/dev/null | grep -qE "EXEC|DYN"; then
      # Remove o RPATH viciado
      patchelf --remove-rpath "$1" 2>/dev/null
      
      # Corrige as dependências que apontam para o seu home
      for lib_path in $(readelf -d "$1" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
        lib_name=$(basename "$lib_path")
        echo "  > Corrigindo dependência em $(basename $1): $lib_name"
        patchelf --replace-needed "$lib_path" "$lib_name" "$1" 2>/dev/null
      done
    fi
  ' _ {} \;
}