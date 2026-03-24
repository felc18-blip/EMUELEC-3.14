# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present 5schatten (https://github.com/5schatten)

PKG_NAME="hatarisa"
PKG_VERSION="3ea4fa8123dedaf2618359dc538b4ef4623d52be"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/hatari/hatari"
PKG_URL="https://github.com/hatari/hatari/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain linux glibc systemd alsa-lib SDL2 portaudio zlib capsimg libpng"
PKG_LONGDESC="Hatari is an Atari ST/STE/TT/Falcon emulator"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DCMAKE_SKIP_RPATH=ON \
                         -DCMAKE_SKIP_INSTALL_RPATH=ON \
                         -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF \
                         -DDATADIR=/usr/config/hatari \
                         -DBIN2DATADIR=../../storage/.config/hatari \
                         -DCAPSIMAGE_INCLUDE_DIR=${PKG_BUILD}/src/include \
                         -DCAPSIMAGE_LIBRARY=${PKG_BUILD}/libcapsimage.so.5.1"

  # copy IPF Support Library include files
  mkdir -p ${PKG_BUILD}/src/includes/caps/
  cp -R $(get_build_dir capsimg)/LibIPF/* ${PKG_BUILD}/src/includes/caps/
  cp -R $(get_build_dir capsimg)/Core/CommonTypes.h ${PKG_BUILD}/src/includes/caps/
  cp -R $(get_install_dir capsimg)/usr/lib/libcapsimage.so.5.1 ${PKG_BUILD}/

  # REMOVIDO: A linha que forçava o rpath sujo foi apagada daqui.
}

makeinstall_target() {
  # create directories
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/config/hatari

  # copy config files  
  touch ${INSTALL}/usr/config/hatari/hatari.nvram
  cp -R ${PKG_DIR}/config/* ${INSTALL}/usr/config/hatari

  # copy binary & start script
  cp src/hatari ${INSTALL}/usr/bin
  cp -R ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
}

# FUNÇÃO DE LIMPEZA GARANTIDA
post_makeinstall_target() {
  echo "--- Sanitizando RPATH do Hatari ---"
  find ${INSTALL} -type f -exec patchelf --remove-rpath {} \; 2>/dev/null
}