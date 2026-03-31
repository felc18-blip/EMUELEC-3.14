# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="squashfs-tools"
PKG_VERSION="4.7.5"
PKG_SHA256="547b7b7f4d2e44bf91b6fc554664850c69563701deab9fd9cd7e21f694c88ea6"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/plougher/squashfs-tools"
PKG_URL="https://github.com/plougher/squashfs-tools/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"

# ✔️ Mantendo as dependências de compressão completas para o HOST
PKG_DEPENDS_HOST="ccache:host zlib:host lzo:host xz:host zstd:host"
PKG_NEED_UNPACK="$(get_pkg_directory zlib) $(get_pkg_directory lzo) $(get_pkg_directory xz) $(get_pkg_directory zstd)"

PKG_LONGDESC="Tools for squashfs, a highly compressed read-only filesystem for Linux."
PKG_TOOLCHAIN="manual"

make_host() {
  # Compilando o mksquashfs com suporte a todos os motores modernos
  make -C squashfs-tools \
          mksquashfs \
          XZ_SUPPORT=1 \
          LZO_SUPPORT=1 \
          LZ4_SUPPORT=0 \
          ZSTD_SUPPORT=1 \
          XATTR_SUPPORT=0 \
          XATTR_DEFAULT=0 \
          INCLUDEDIR="-I. -I${TOOLCHAIN}/include"
}

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/bin
  cp squashfs-tools/mksquashfs ${TOOLCHAIN}/bin
}