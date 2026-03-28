# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2017 Escalade
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="at-spi2-core"
PKG_VERSION="2.57.0"
PKG_SHA256="942070eff19155b7d6ce5557f1a020015287b840048536e9ef9a28c4e9ce428c"
PKG_LICENSE="OSS"
PKG_SITE="https://www.gnome.org/"
PKG_URL="https://download.gnome.org/sources/at-spi2-core/${PKG_VERSION:0:4}/at-spi2-core-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain at-spi2-core atk libX11 libxml2"
PKG_LONGDESC="A GTK+ module that bridges ATK to D-Bus at-spi."
