# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="usbutils"
PKG_VERSION="017"
PKG_LICENSE="GPL"
PKG_SITE="http://www.linux-usb.org/"
PKG_URL="http://kernel.org/pub/linux/utils/usb/usbutils/${PKG_NAME}-${PKG_VERSION}.tar.xz"

# ADICIONADO: libiconv para evitar o erro de 'undefined reference'
PKG_DEPENDS_TARGET="toolchain libusb systemd libiconv"

PKG_LONGDESC="This package contains various utilities for inspecting and setting of devices connected to the USB bus."

# ADICIONADO: Força o linker a linkar a biblioteca iconv
PKG_CONFIGURE_OPTS_TARGET="LIBS=-liconv"

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/bin/lsusb.py
  rm -rf ${INSTALL}/usr/bin/usbhid-dump
}