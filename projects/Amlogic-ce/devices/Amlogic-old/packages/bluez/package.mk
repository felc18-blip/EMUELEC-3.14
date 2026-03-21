# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="bluez"
PKG_VERSION="5.50"
PKG_SHA256="c44b776660bf78e664e388b979da152976296e444dece833f3ddbd5be5a3b1b4"
PKG_LICENSE="GPL"
PKG_SITE="http://www.bluez.org/"
PKG_URL="https://git.kernel.org/pub/scm/bluetooth/bluez.git/snapshot/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain dbus glib readline systemd"
PKG_LONGDESC="Bluetooth Tools and System Daemons for Linux."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="+lto"

if build_with_debug; then
  BLUEZ_CONFIG="--enable-debug"
else
  BLUEZ_CONFIG="--disable-debug"
fi

BLUEZ_CONFIG="$BLUEZ_CONFIG --enable-monitor --enable-test"

PKG_MAKE_OPTS_TARGET="LIBS=-lncursesw"

PKG_CONFIGURE_OPTS_TARGET="--disable-dependency-tracking \
                           --disable-silent-rules \
                           --enable-library \
                           --enable-udev \
                           --disable-cups \
                           --disable-obex \
                           --enable-client \
                           --enable-systemd \
                           --enable-tools --enable-deprecated \
                           --enable-datafiles \
                           --disable-experimental \
                           --enable-sixaxis \
                           --with-gnu-ld \
                           $BLUEZ_CONFIG \
                           storagedir=/storage/.cache/bluetooth"

pre_configure_target() {
  cd $PKG_BUILD
  rm -rf .$TARGET_NAME
  export LDFLAGS=""
  export LIBS=""
  export ac_cv_prog_cc_works=yes
}

post_makeinstall_target() {
  rm -rf $INSTALL/usr/lib/systemd
  rm -rf $INSTALL/usr/bin/bccmd
  rm -rf $INSTALL/usr/bin/bluemoon
  rm -rf $INSTALL/usr/bin/ciptool
  rm -rf $INSTALL/usr/share/dbus-1
  
  mkdir -p $INSTALL/etc/bluetooth
    cp src/main.conf $INSTALL/etc/bluetooth
    sed -i $INSTALL/etc/bluetooth/main.conf \
        -e "s|^#\[Policy\]|\[Policy\]|g" \
        -e "s|^#AutoEnable.*|AutoEnable=true|g"
  
  mkdir -p $INSTALL/usr/share/services
    cp -P $PKG_DIR/default.d/*.conf $INSTALL/usr/share/services
    ln -sf /usr/lib/firmware $INSTALL/etc/firmware
    sed -i 's/-lbluetooth//g' ${PKG_BUILD}/lib/bluez.pc
    cp -P ${PKG_BUILD}/lib/bluez.pc ${SYSROOT_PREFIX}/usr/lib/pkgconfig

  # --- A VACINA AGRESSIVA AQUI ---
  echo "--- Sanitizando BlueZ 5.50 (Versão OLD) ---"
  find ${INSTALL} -type f -exec sh -c '
    if readelf -h "$1" 2>/dev/null | grep -qE "EXEC|DYN"; then
      # Limpa RPATH e RUNPATH
      patchelf --set-rpath "" "$1" 2>/dev/null || patchelf --remove-rpath "$1" 2>/dev/null
      
      # Corrige links viciados ao seu /home/felipe
      for full_lib in $(readelf -d "$1" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
        lib_only=$(basename "$full_lib")
        echo "  > Corrigindo: $lib_only em $(basename $1)"
        patchelf --replace-needed "$full_lib" "$lib_only" "$1" 2>/dev/null
      done
    fi
  ' _ {} \;
}

post_install() {
  enable_service bluetooth-defaults.service
  enable_service bluetooth.service
  enable_service obex.service
}