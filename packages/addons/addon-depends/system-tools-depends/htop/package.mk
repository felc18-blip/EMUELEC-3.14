# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="htop"
PKG_VERSION="3.4.1"
PKG_SHA256="af9ec878f831b7c27d33e775c668ec79d569aa781861c995a0fbadc1bdb666cf"
PKG_LICENSE="GPL"
PKG_SITE="https://hisham.hm/htop"
PKG_URL="https://github.com/htop-dev/htop/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ncurses"
PKG_LONGDESC="An interactive process viewer for Unix."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="-sysroot -cfg-libs"

PKG_CONFIGURE_OPTS_TARGET=" \
  --enable-unicode \
  --disable-static \
  HTOP_NCURSES_CONFIG_SCRIPT=ncursesw-config"

pre_configure_target() {
  # necessário pro resize + ncurses moderno
  export CPPFLAGS="${CPPFLAGS} -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE"

  # fallback garantido (resolve 100% dos casos)
  export CPPFLAGS="${CPPFLAGS} -DKEY_RESIZE=410"

  export LDFLAGS="${LDFLAGS} -pthread"
}
