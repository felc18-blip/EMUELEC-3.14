# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="alsa-plugins"
PKG_VERSION="1.2.7.1"
PKG_SHA256="8c337814954bb7c167456733a6046142a2931f12eccba3ec2a4ae618a3432511"
PKG_LICENSE="GPL"
PKG_SITE="http://www.alsa-project.org/"
PKG_URL="ftp://ftp.alsa-project.org/pub/plugins/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain alsa-lib"
PKG_LONGDESC="Alsa plugins."

if [ "${PULSEAUDIO_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" pulseaudio"
  SUBDIR_PULSEAUDIO="pulse"
fi

PKG_CONFIGURE_OPTS_TARGET="--with-plugindir=/usr/lib/alsa --enable-samplerate"
PKG_MAKE_OPTS_TARGET=""
PKG_MAKEINSTALL_OPTS_TARGET=""

post_configure_target() {
  libtool_remove_rpath libtool
}

post_makeinstall_target() {
  echo "--- Sanitizando binários do Alsa-Plugins (Modo Forçado) ---"
  
  # 1. Garante que os binários de teste foram instalados
  if [ -f "${PKG_BUILD}/test/playsound" ]; then
    mkdir -p ${INSTALL}/usr/bin
    cp ${PKG_BUILD}/test/playsound ${INSTALL}/usr/bin/
    cp ${PKG_BUILD}/test/playsound_simple ${INSTALL}/usr/bin/
    chmod +x ${INSTALL}/usr/bin/playsound*
  fi

  # 2. A lógica que você rodou no terminal, adaptada para o script
  for f in playsound playsound_simple; do
    arquivo="${INSTALL}/usr/bin/$f"
    if [ -f "$arquivo" ]; then
      echo "  > Removendo RPATH/RUNPATH de: $f"
      patchelf --remove-rpath "$arquivo" 2>/dev/null
      
      # Remove links absolutos (NEEDED) caso existam
      for lib in $(readelf -d "$arquivo" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
        lib_name=$(basename "$lib")
        echo "  > Corrigindo dependência: $lib_name"
        patchelf --replace-needed "$lib" "$lib_name" "$arquivo" 2>/dev/null
      done
    fi
  done

  # 3. Limpa também os plugins em usr/lib/alsa para não sobrar nada
  find ${INSTALL}/usr/lib/alsa -type f -name "*.so*" -exec patchelf --remove-rpath {} \; 2>/dev/null
}