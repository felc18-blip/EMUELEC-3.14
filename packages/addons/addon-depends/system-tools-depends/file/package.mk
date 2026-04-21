# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="file"
PKG_VERSION="5.48-dev"
PKG_SHA256="dd12a49d54fd7e74609ba6afb479a564b9d4d742eb7be6508140e2a92026e879"
PKG_LICENSE="BSD"
PKG_SITE="https://github.com/file/file"
PKG_URL="https://github.com/file/file/archive/refs/heads/master.tar.gz"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain file:host zlib"
PKG_LONGDESC="The file utility is used to determine the types of various files."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="-sysroot"

PKG_CONFIGURE_OPTS_HOST="--enable-fsect-man5 \
                         --enable-static \
                         --disable-shared"

PKG_CONFIGURE_OPTS_TARGET="${PKG_CONFIGURE_OPTS_HOST}"
