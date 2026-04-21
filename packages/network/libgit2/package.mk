# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="libgit2"
PKG_VERSION="1.7.2"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://libgit2.org"
PKG_URL="https://github.com/libgit2/libgit2/archive/refs/tags/v${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain openssl zlib"
PKG_SHORTDESC="A portable, pure C implementation of the Git core methods."
PKG_TOOLCHAIN="cmake"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=ON \
                       -DBUILD_TESTS=OFF \
                       -DUSE_SSH=OFF \
                       -DBUILD_CLI=OFF"

# -------------------------------------------------

makeinstall_target() {

  # CMAKE INSTALL CORRETO
  DESTDIR=${INSTALL} cmake --install .

  # --- GARANTE LIB NA IMAGEM ---
  mkdir -p ${INSTALL}/usr/lib

  cp -v ${INSTALL}/usr/lib/libgit2.so* ${INSTALL}/usr/lib/ 2>/dev/null || true

  ln -sf libgit2.so.1.7 ${INSTALL}/usr/lib/libgit2.so 2>/dev/null || true
}
