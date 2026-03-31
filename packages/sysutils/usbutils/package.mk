# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="usbutils"
PKG_VERSION="018"
PKG_SHA256="83f68b59b58547589c00266e82671864627593ab4362d8c807f50eea923cad93"
PKG_LICENSE="GPL"
PKG_SITE="http://www.linux-usb.org/"
PKG_URL="http://kernel.org/pub/linux/utils/usb/usbutils/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain libusb systemd libiconv"
PKG_LONGDESC="Ferramentas para inspecionar e configurar dispositivos no barramento USB."

# MÁGICA DE ELITE: O Meson exige que flags de linkagem extras sejam passadas via c_link_args
PKG_MESON_OPTS_TARGET="-Dc_link_args='-liconv'"

post_makeinstall_target() {
  # Limpeza de scripts Python e dump para economizar espaço na squashfs
  rm -rf ${INSTALL}/usr/bin/lsusb.py
  rm -rf ${INSTALL}/usr/bin/usbhid-dump
}