# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue
# Copyright (C) 2019-present Team LibreELEC

PKG_NAME="nano"
PKG_VERSION="8.7.1"
PKG_SHA256="76f0dcb248f2e2f1251d4ecd20fd30fb400a360a3a37c6c340e0a52c2d1cdedf"
PKG_LICENSE="GPL"
PKG_SITE="https://www.nano-editor.org/"
PKG_URL="https://www.nano-editor.org/dist/v${PKG_VERSION%%.*}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain ncurses"
PKG_LONGDESC="Nano is an enhanced clone of the Pico text editor."
PKG_BUILD_FLAGS="-cfg-libs"

PKG_CONFIGURE_OPTS_TARGET="--with-curses \
                           --enable-utf8 \
                           --disable-nls \
                           --disable-libmagic \
                           --disable-wrapping"

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/share/nano

  mkdir -p ${INSTALL}/etc
  cp -a ${PKG_DIR}/config/* ${INSTALL}/etc/

  mkdir -p ${INSTALL}/usr/share/nano

  # mantém lógica original, mas mais limpa
  PKG_FILE_LIST="css html java javascript json php python sh xml"

  for FILE_TYPE in ${PKG_FILE_LIST}; do
    [ -f ${PKG_BUILD}/syntax/${FILE_TYPE}.nanorc ] && \
      cp -a ${PKG_BUILD}/syntax/${FILE_TYPE}.nanorc ${INSTALL}/usr/share/nano/
  done
}
