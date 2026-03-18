PKG_NAME="libxcrypt"
PKG_VERSION="4.4.36"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/besser82/libxcrypt"
PKG_URL="https://github.com/besser82/libxcrypt/releases/download/v${PKG_VERSION}/libxcrypt-${PKG_VERSION}.tar.xz"
PKG_INSTALL_TARGET="yes"
PKG_INSTALL_SYSROOT="yes"
PKG_DEPENDS_TARGET="toolchain"

PKG_CONFIGURE_OPTS_TARGET="--enable-shared \
                           --disable-static \
                           --enable-hashes=all \
                           --enable-obsolete-api=glibc \
                           --disable-werror"
						   
make_install_target() {
  # 1. Instala na pasta do pacote (para o cartão SD)
  make DESTDIR=${INSTALL} install

  # 2. Instala no Sysroot do Toolchain (para o Systemd encontrar)
  make DESTDIR=${SYSROOT_PREFIX} install
}

post_makeinstall_target() {
  # Garante que o link simbólico exista (o Meson exige isso)
  if [ -f ${SYSROOT_PREFIX}/usr/lib/libcrypt.so.1 ]; then
    ln -sf libcrypt.so.1 ${SYSROOT_PREFIX}/usr/lib/libcrypt.so
  fi
}