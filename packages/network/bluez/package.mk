# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="bluez"
PKG_VERSION="5.72"
PKG_SHA256="499d7fa345a996c1bb650f5c6749e1d929111fa6ece0be0e98687fee6124536e"
PKG_LICENSE="GPL"
PKG_SITE="http://www.bluez.org/"
PKG_URL="https://www.kernel.org/pub/linux/bluetooth/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain dbus glib readline systemd"
PKG_LONGDESC="Bluetooth Tools and System Daemons for Linux."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="+lto"

if build_with_debug; then
  BLUEZ_CONFIG="--enable-debug"
else
  BLUEZ_CONFIG="--disable-debug"
fi

BLUEZ_CONFIG+=" --enable-monitor --enable-test"

PKG_CONFIGURE_OPTS_TARGET="--disable-dependency-tracking \
                           --disable-silent-rules \
                           --enable-library \
                           --enable-udev \
                           --disable-cups \
                           --disable-obex \
                           --enable-client \
                           --enable-systemd \
                           --enable-tools \
                           --enable-deprecated \
                           --enable-datafiles \
                           --disable-manpages \
                           --disable-experimental \
                           --enable-sixaxis \
                           --with-gnu-ld \
                           ${BLUEZ_CONFIG} \
                           storagedir=/storage/.cache/bluetooth"

pre_configure_target() {
# bluez fails to build in subdirs
  cd ${PKG_BUILD}
    rm -rf .${TARGET_NAME}

  export LIBS="-lncurses"
}

post_configure_target() {
  libtool_remove_rpath libtool
}

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/lib/systemd
  safe_remove ${INSTALL}/usr/bin/bluemoon
  safe_remove ${INSTALL}/usr/bin/ciptool

  mkdir -p ${INSTALL}/etc/bluetooth
    cp src/main.conf ${INSTALL}/etc/bluetooth
    sed -i ${INSTALL}/etc/bluetooth/main.conf \
        -e "s|^#\[Policy\]|\[Policy\]|g" \
        -e "s|^#AutoEnable.*|AutoEnable=true|g" \
        -e "s|^#JustWorksRepairing.*|JustWorksRepairing=always|g"
    echo "[General]" > ${INSTALL}/etc/bluetooth/input.conf
    echo "ClassicBondedOnly=false" >> ${INSTALL}/etc/bluetooth/input.conf

  mkdir -p ${INSTALL}/usr/share/services
    cp -P ${PKG_DIR}/default.d/*.conf ${INSTALL}/usr/share/services

  # bluez looks in /etc/firmware/
    ln -sf /usr/lib/firmware ${INSTALL}/etc/firmware

  # pulseaudio checks for bluez via pkgconfig but lib is not actually needed
    sed -i 's/-lbluetooth//g' ${PKG_BUILD}/lib/bluez.pc
    cp -P ${PKG_BUILD}/lib/bluez.pc ${SYSROOT_PREFIX}/usr/lib/pkgconfig
  
  # copy bluezutils.py  
    mkdir -p ${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}
  cp -rf ${INSTALL}/usr/lib/bluez/test/bluezutils.py ${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}
  rm -rf ${INSTALL}/usr/lib/bluez/test

  # --- HIGIENIZAÇÃO AGRESSIVA E FINAL ---
  echo "--- Sanitizando binários do BlueZ (mpris-proxy, bluetoothctl, etc) ---"
  
  # Remove arquivos .la primeiro (eles são a fonte da contaminação do Libtool)
  find ${INSTALL} -name "*.la" -delete

  # Varredura completa por RPATH e caminhos absolutos
  find ${INSTALL} -type f -exec sh -c '
    if readelf -h "$1" 2>/dev/null | grep -qE "EXEC|DYN"; then
      # Tenta zerar o RPATH e o RUNPATH (set-rpath "" é mais eficaz que remove-rpath)
      patchelf --set-rpath "" "$1" 2>/dev/null || patchelf --remove-rpath "$1" 2>/dev/null
      
      # Procura especificamente por dependências NEEDED que apontam para o seu PC
      for full_lib in $(readelf -d "$1" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
        lib_only=$(basename "$full_lib")
        echo "  > Higienizando: $(basename $1) (vinculado a $lib_only)"
        patchelf --replace-needed "$full_lib" "$lib_only" "$1" 2>/dev/null
      done
    fi
  ' _ {} \;

  # Verificação direta nos binários problemáticos
  for binario in mpris-proxy bluetoothctl obexd bluetoothd; do
    target_bin=$(find ${INSTALL} -name "$binario")
    if [ -n "$target_bin" ]; then
       echo "  > Aplicando trava de segurança em: $binario"
       patchelf --set-rpath "" "$target_bin" 2>/dev/null
    fi
  done
}

post_install() {
  enable_service bluetooth-defaults.service
  enable_service bluetooth.service
  enable_service obex.service
}