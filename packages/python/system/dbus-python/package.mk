# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present Team CoreELEC (https://coreelec.org)

PKG_NAME="dbus-python"
PKG_VERSION="1.3.2"
PKG_SHA256="ad67819308618b5069537be237f8e68ca1c7fcc95ee4a121fe6845b1418248f8"
PKG_LICENSE="GPL"
PKG_SITE="https://freedesktop.org/wiki/Software/dbus"
PKG_URL="https://dbus.freedesktop.org/releases/dbus-python/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python3 dbus dbus-glib"
PKG_LONGDESC="D-BUS is a message bus, used for sending messages between applications."
PKG_BUILD_FLAGS="+lto"
PKG_TOOLCHAIN="autotools"

pre_configure_target() {
  export PKG_CONFIG_PATH="${SYSROOT_PREFIX}/usr/lib/pkgconfig"
  export PYTHON_CONFIG="${SYSROOT_PREFIX}/usr/bin/python3-config"
  export PYTHON_INCLUDES="$(${SYSROOT_PREFIX}/usr/bin/python3-config --includes)"
  export PYTHON_LIBS="$(${SYSROOT_PREFIX}/usr/bin/python3-config --ldflags --embed)"
}

post_makeinstall_target() {
  python_remove_source

  # --- INÍCIO DA LIMPEZA PESADA (Focado em módulos Python .so) ---
  echo "--- Sanitizando bindings do dbus-python (Limpando rastros do PC) ---"
  
  # Varre toda a pasta de instalação (essencial para achar os .so em site-packages)
  find ${INSTALL} -type f -name "*.so*" -exec sh -c '
    if readelf -h "$1" 2>/dev/null | grep -qE "EXEC|DYN"; then
      # Remove RPATH/RUNPATH
      patchelf --remove-rpath "$1" 2>/dev/null
      
      # Substitui caminhos absolutos (/home/felipe/...) pelo nome puro da lib
      for lib_path in $(readelf -d "$1" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
        lib_name=$(basename "$lib_path")
        echo "  > Corrigindo dependência em $(basename $1): $lib_name"
        patchelf --replace-needed "$lib_path" "$lib_name" "$1" 2>/dev/null
      done
    fi
  ' _ {} \;
}