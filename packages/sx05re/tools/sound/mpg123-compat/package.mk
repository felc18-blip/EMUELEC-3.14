# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present 5schatten (https://github.com/5schatten)

PKG_NAME="mpg123-compat"
PKG_VERSION="1.28.2"
PKG_SHA256="7eefd4b68fdac7e138d04c37efe12155a8ebf25a5bccf0fb7e775af22d21db00"
PKG_LICENSE="LGPLv2"
PKG_SITE="http://www.mpg123.org/"
PKG_URL="http://downloads.sourceforge.net/sourceforge/mpg123/mpg123-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain alsa-lib SDL2"
PKG_LONGDESC="A console based real time MPEG Audio Player for Layer 1, 2 and 3."
PKG_BUILD_FLAGS="-fpic"

if [ "${PULSEAUDIO_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET="${PKG_DEPENDS_TARGET} pulseaudio"
  PKG_CONFIGURE_OPTS_TARGET="--with-default-audio=pulse --with-audio=alsa,pulse"
else
  PKG_CONFIGURE_OPTS_TARGET="--with-default-audio=alsa --with-audio=alsa"
fi

# --- ADICIONANDO A SANITIZAÇÃO NO POST_MAKEINSTALL ---
post_makeinstall_target() {
  echo "--- Sanitizando mpg123-compat (O Fim do Vilão Final) ---"
  
  find ${INSTALL} -type f -exec sh -c '
    if readelf -d "$1" 2>/dev/null | grep -q "/home/felipe"; then
      echo "  > Limpando plugin: $(basename $1)"
      
      # Zera RPATH/RUNPATH
      patchelf --set-rpath "" "$1" 2>/dev/null || patchelf --remove-rpath "$1" 2>/dev/null
      
      # Corrige links viciados
      for lib_full in $(readelf -d "$1" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
        lib_nome=$(basename "$full_lib")
        echo "    >> Corrigindo link: $lib_nome"
        patchelf --replace-needed "$lib_full" "$lib_nome" "$1" 2>/dev/null
      done
    fi
  ' _ {} \;
}