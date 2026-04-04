# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)


PKG_NAME="usbutils"
PKG_VERSION="019"
PKG_SHA256="659f40c440e31ba865c52c818a33d3ba6a97349e3353f8b1985179cb2aa71ec5"
PKG_LICENSE="GPL"
PKG_SITE="http://www.linux-usb.org/"
PKG_URL="http://kernel.org/pub/linux/utils/usb/usbutils/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain libusb systemd libiconv"
PKG_LONGDESC="Ferramentas para inspecionar e configurar dispositivos no barramento USB."


post_makeinstall_target() {
  # Limpeza de scripts Python e dump para economizar espaço na squashfs
  rm -rf ${INSTALL}/usr/bin/lsusb.py
  rm -rf ${INSTALL}/usr/bin/usbhid-dump
}
