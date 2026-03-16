# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="imagemagick"
PKG_VERSION="2c4205d20c5495f15d706c26084eb327d4b859bb"
PKG_SHA256="0d038fa15f28e290bb8850c8fc954bc899b007d1ec1d09b88900d4bc14c53e31"
PKG_LICENSE="http://www.imagemagick.org/script/license.php"
PKG_SITE="https://github.com/ImageMagick/ImageMagick"
PKG_URL="https://github.com/ImageMagick/ImageMagick/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Software suite to create, edit, compose, or convert bitmap images"

PKG_CONFIGURE_OPTS_TARGET="--disable-openmp \
                           --disable-static \
                           --enable-shared \
                           --with-pango=no \
                           --with-utilities=yes \
                           --with-x=no"

makeinstall_target() {
  make install DESTDIR=${INSTALL} ${PKG_MAKEINSTALL_OPTS_TARGET}
  rm ${INSTALL}/usr/bin/*config
}

# --- FUNÇÃO DE LIMPEZA ADICIONADA ---
post_makeinstall_target() {
  echo "--- Sanitizando binários do ImageMagick (Limpando rastros do PC) ---"
  
  # Varre usr/bin onde ficam o magick, convert, identify, etc.
  find ${INSTALL}/usr/bin -type f -exec sh -c '
    # Remove RPATH/RUNPATH
    patchelf --remove-rpath "$1" 2>/dev/null
    
    # Substitui caminhos absolutos (/home/felipe/...) pelo nome puro da lib
    for lib_path in $(readelf -d "$1" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
      lib_name=$(basename "$lib_path")
      echo "  > Corrigindo dependência em $(basename $1): $lib_name"
      patchelf --replace-needed "$lib_path" "$lib_name" "$1" 2>/dev/null
    done
  ' _ {} \;

  # Como o ImageMagick usa MUITAS bibliotecas compartilhadas (.so),
  # vamos limpar o RPATH delas também para garantir estabilidade.
  echo "--- Limpando RPATH das bibliotecas do ImageMagick ---"
  find ${INSTALL}/usr/lib -type f -name "*.so*" -exec patchelf --remove-rpath {} \; 2>/dev/null
}