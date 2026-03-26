# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="wget"
PKG_VERSION="1.21.4"
PKG_LICENSE="GPL"
PKG_SITE="http://www.gnu.org/software/wget/"
PKG_URL="http://ftp.gnu.org/gnu/wget/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host"
PKG_DEPENDS_TARGET="toolchain gnutls"
PKG_LONGDESC="GNU Wget is a free software package for retrieving files using HTTP, HTTPS, FTP and FTPS"
pre_configure_target() {
PKG_CONFIGURE_OPTS_TARGET+=" --with-ssl=openssl"
}

makeinstall_target() {
mkdir -p ${INSTALL}/usr/bin
cp ${PKG_BUILD}/.${TARGET_NAME}/src/wget ${INSTALL}/usr/bin/wget
}
