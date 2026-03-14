# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="dosbox-pure"
PKG_VERSION="fe0bdab8a04eedb912634d89ad8137de75529cff"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/schellingb/dosbox-pure"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain linux glibc glib systemd dbus alsa-lib SDL2 SDL2_net SDL_sound libpng zlib libvorbis flac libogg fluidsynth-git munt opusfile"
PKG_LONGDESC="DOSBox Pure is a new fork of DOSBox built for RetroArch/Libretro aiming for simplicity and ease of use."
PKG_TOOLCHAIN="make"

pre_configure_target() {
  if [ "${DEVICE}" == "Amlogic-old" ]; then
    PKG_MAKE_OPTS_TARGET="platform=emuelec"
  elif [ "${DEVICE}" == "Amlogic-ng" ] || [ "${DEVICE}" == "Amlogic-no" ] || [ "${DEVICE}" == "Amlogic-ogu" ]; then
    PKG_MAKE_OPTS_TARGET="platform=emuelec-ng"
  else
    PKG_MAKE_OPTS_TARGET="platform=emuelec-hh"
  fi
}

make_target() {
  # Injetamos os diretórios internos do source (-I...) para que o compilador ache o dosbox.h e outros
  # Usamos CXXFLAGS para C++ e mantemos o -shared no LDFLAGS
  make -j$(nproc) ${PKG_MAKE_OPTS_TARGET} \
       CC="${CC}" \
       CXX="${CXX}" \
       STRIP="${STRIP}" \
       CFLAGS="${CFLAGS} -fPIC -I. -Iinclude -Isrc -Isrc/gui" \
       CXXFLAGS="${CXXFLAGS} -fPIC -I. -Iinclude -Isrc -Isrc/gui" \
       LDFLAGS="${LDFLAGS} -shared -Wl,--gc-sections"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  
  # O Makefile pode gerar o arquivo com nomes levemente diferentes dependendo da plataforma
  # Procuramos por qualquer .so gerado que contenha "dosbox_pure"
  if [ -f "dosbox_pure_libretro.so" ]; then
    cp -f dosbox_pure_libretro.so ${INSTALL}/usr/lib/libretro/
  else
    cp -f *.so ${INSTALL}/usr/lib/libretro/dosbox_pure_libretro.so
  fi
  
  if [ -f "dosbox_pure_libretro.info" ]; then
    cp -f dosbox_pure_libretro.info ${INSTALL}/usr/lib/libretro/
  fi
}