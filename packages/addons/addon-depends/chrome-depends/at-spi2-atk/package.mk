# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2017 Escalade
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="at-spi2-core"
PKG_VERSION="2.60.1"
PKG_SHA256="f99b87e3c1674f5fbc417cc9c1d9e261c0f29aab0550ad6369805031d12f6852"
PKG_LICENSE="OSS"
PKG_SITE="https://www.gnome.org/"
PKG_URL="https://download.gnome.org/sources/at-spi2-core/${PKG_VERSION:0:4}/at-spi2-core-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain at-spi2-core atk libX11 libxml2"
PKG_LONGDESC="A GTK+ module that bridges ATK to D-Bus at-spi."
