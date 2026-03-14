PKG_NAME="libxcrypt"
PKG_VERSION="4.4.36"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/besser82/libxcrypt"
PKG_URL="https://github.com/besser82/libxcrypt/releases/download/v${PKG_VERSION}/libxcrypt-${PKG_VERSION}.tar.xz"

PKG_DEPENDS_TARGET="toolchain"

PKG_CONFIGURE_OPTS_TARGET="\
  --enable-shared \
  --disable-static \
  --enable-hashes=all \
  --enable-obsolete-api=glibc \
  --disable-werror \
"
