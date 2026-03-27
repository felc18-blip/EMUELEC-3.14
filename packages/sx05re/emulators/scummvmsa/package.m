# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert
# Updated for EmuELEC

PKG_NAME="scummvmsa"
PKG_VERSION="2.9.1"
PKG_REV="1"
PKG_LICENSE="GPL2"
PKG_SITE="https://github.com/scummvm/scummvm"
PKG_URL="${PKG_SITE}/archive/refs/tags/v${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_net freetype fluidsynth-git libmad timidity"

PKG_SHORTDESC="Script Creation Utility for Maniac Mansion Virtual Machine"
PKG_LONGDESC="ScummVM is a program which allows you to run classic graphical point-and-click adventure games."

pre_configure_target() {
  cd ${PKG_BUILD}

  # garantir uso do SDL2
  sed -i "s|sdl-config|sdl2-config|g" configure

  TARGET_CONFIGURE_OPTS="--host=${TARGET_NAME} \
                         --backend=sdl \
                         --enable-vkeybd \
                         --enable-sdl-ts-vmouse \
                         --disable-debug \
                         --enable-release \
                         --opengl-mode=gles2 \
                         --with-sdl-prefix=${SYSROOT_PREFIX}/usr"
}

configure_target() {
  cd ${PKG_BUILD}
  ./configure ${TARGET_CONFIGURE_OPTS}
}

make_target() {
  cd ${PKG_BUILD}
  make ${PKG_MAKE_OPTS_TARGET} V=1
}

post_makeinstall_target() {

  # config do EmuELEC
  mkdir -p ${INSTALL}/usr/config/scummvm
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/scummvm/

  # temas do scummvm
  mkdir -p ${INSTALL}/usr/config/scummvm/themes
  cp -rf ${PKG_BUILD}/gui/themes/* ${INSTALL}/usr/config/scummvm/themes

  # teclado virtual
  mkdir -p ${INSTALL}/usr/config/scummvm/extra
  cp -rf ${PKG_BUILD}/backends/vkeybd/packs/*.zip ${INSTALL}/usr/config/scummvm/extra

  # mover binário principal
  if [ -d ${INSTALL}/usr/local/bin ]; then
    mv ${INSTALL}/usr/local/bin ${INSTALL}/usr/
  fi

  # garantir diretório de executáveis
  mkdir -p ${INSTALL}/usr/bin

  # scripts (compatível com EmuELEC ou JELOS)
  if [ -d ${PKG_DIR}/bin ]; then
    cp -rf ${PKG_DIR}/bin/* ${INSTALL}/usr/bin
  fi

  if [ -d ${PKG_DIR}/sources ]; then
    cp -rf ${PKG_DIR}/sources/* ${INSTALL}/usr/bin
  fi

  chmod 755 ${INSTALL}/usr/bin/* 2>/dev/null || true

  # remover arquivos desnecessários
  for i in appdata applications doc icons man metainfo; do
    rm -rf "${INSTALL}/usr/local/share/${i}"
  done
}