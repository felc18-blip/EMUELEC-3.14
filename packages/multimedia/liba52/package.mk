PKG_NAME="liba52"
PKG_VERSION="0.8.0"
PKG_SITE="https://distfiles.adelielinux.org/source/a52dec"
PKG_URL="${PKG_SITE}/a52dec-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="
  --disable-static
  --enable-shared
"
