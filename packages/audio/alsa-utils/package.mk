# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="alsa-utils"
PKG_VERSION="1.2.10"
PKG_LICENSE="GPL"
PKG_SITE="http://www.alsa-project.org/"
PKG_URL="https://www.alsa-project.org/files/pub/utils/alsa-utils-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain alsa-lib ncurses systemd alsa-ucm-conf"
PKG_LONGDESC="This package includes the utilities for ALSA, like alsamixer, aplay, arecord, alsactl, iecset and speaker-test."
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--disable-alsaconf \
                           --disable-alsaloop \
                           --enable-alsatest \
                           --disable-bat \
                           --disable-dependency-tracking \
                           --disable-nls \
                           --disable-rst2man \
                           --disable-xmlto"

post_makeinstall_target() {
  rm -rf ${INSTALL}/lib ${INSTALL}/var
  rm -rf ${INSTALL}/usr/share/alsa/speaker-test
  rm -rf ${INSTALL}/usr/share/sounds
  rm -rf ${INSTALL}/usr/lib/systemd/system

# remove default udev rule to restore mixer configs, we install our own.
# so we avoid resetting our soundconfig
  rm -rf ${INSTALL}/usr/lib/udev/rules.d/90-alsa-restore.rules

  mkdir -p ${INSTALL}/.noinstall
  for i in aconnect amidi aplaymidi arecordmidi aseqdump aseqnet iecset; do
    if [ -f "${INSTALL}/usr/bin/${i}" ]; then
      mv ${INSTALL}/usr/bin/${i} ${INSTALL}/.noinstall
    fi
  done

  mkdir -p ${INSTALL}/usr/lib/udev
  cp ${PKG_DIR}/scripts/soundconfig ${INSTALL}/usr/lib/udev

  # --- LIMPEZA PESADA (Modo Global para ALSA) ---
  echo "--- Sanitizando binários do ALSA-UTILS (Limpando rastros do PC) ---"
  
  # Varre tudo dentro de ${INSTALL} para garantir que playsound e outros em pastas ocultas sejam pegos
  find ${INSTALL} -type f -exec sh -c '
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