# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="minizip"
PKG_VERSION="4.0.1"
PKG_LICENSE="zlib"
PKG_SITE="https://github.com/nmoinvaz/minizip"
PKG_URL="https://github.com/nmoinvaz/minizip/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="zlib"
PKG_LONGDESC="Minizip zlib contribution fork with latest bug fixes"

PKG_CMAKE_OPTS_TARGET="-DUSE_AES=OFF \
                       -DMZ_BUILD_TEST=ON \
                       -DMZ_BUILD_TOOLS=ON"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin

  cp -v ${PKG_BUILD}/.${TARGET_NAME}/minizip ${INSTALL}/usr/bin/
}
