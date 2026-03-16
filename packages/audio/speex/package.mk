# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="speex"
PKG_VERSION="1.2.1"
PKG_SHA256="cc55cce69d8753940d56936f7a1fe6db4b302df144aec93a92de1c65b1a87681"
PKG_LICENSE="BSD"
PKG_SITE="https://speex.org"
PKG_URL="https://gitlab.xiph.org/xiph/speex/-/archive/Speex-${PKG_VERSION}/speex-Speex-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="An Open Source Software patent-free audio compression format designed for speech."
PKG_TOOLCHAIN="autotools"

# --- FUNÇÃO DE LIMPEZA ADICIONADA ---
post_makeinstall_target() {
  echo "--- Sanitizando binários do Speex (Limpando rastros do PC) ---"
  
  # Varre usr/bin onde ficam o speexenc e speexdec
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
}