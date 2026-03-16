# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="mpg123"
PKG_VERSION="1.31.3"
PKG_SHA256="1ca77d3a69a5ff845b7a0536f783fee554e1041139a6b978f6afe14f5814ad1a"
PKG_LICENSE="LGPLv2"
PKG_SITE="https://www.mpg123.org/"
PKG_URL="https://downloads.sourceforge.net/sourceforge/mpg123/mpg123-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain alsa-lib"
PKG_LONGDESC="A console based real time MPEG Audio Player for Layer 1, 2 and 3."
PKG_BUILD_FLAGS="-sysroot"

# Mantendo habilitado o que é necessário para os plugins funcionarem
PKG_CONFIGURE_OPTS_TARGET="--enable-shared \
                           --enable-static \
                           --with-audio=alsa \
                           --with-default-audio=alsa"

post_makeinstall_target() {
  echo "--- INICIANDO FAXINA AGRESSIVA NO mpg123 ---"

  # 1. Atacamos a pasta de instalação completa
  # Usamos -name "*" para garantir que pegamos arquivos sem extensão se necessário
  find ${INSTALL} -type f -exec sh -c '
    if readelf -d "$1" 2>/dev/null | grep -qE "RPATH|RUNPATH|NEEDED"; then
      if readelf -d "$1" 2>/dev/null | grep -q "/home/felipe"; then
        echo "  > Limpando rastro em: $(basename $1)"
        
        # Remove RPATH/RUNPATH
        patchelf --remove-rpath "$1" 2>/dev/null
        
        # Corrige links de dependências (NEEDED) que apontam para o seu PC
        for lib_path in $(readelf -d "$1" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
          lib_name=$(basename "$lib_path")
          echo "    >> Substituindo link absoluto por: $lib_name"
          patchelf --replace-needed "$lib_path" "$lib_name" "$1" 2>/dev/null
        done
      fi
    fi
  ' _ {} \;

  echo "--- FAXINA mpg123 CONCLUÍDA ---"
}