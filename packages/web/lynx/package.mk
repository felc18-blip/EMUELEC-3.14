# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="lynx"
PKG_VERSION="2.8.9rel.1"
PKG_LICENSE="LGPL"
PKG_SITE="https://invisible-island.net"
PKG_URL="${PKG_SITE}/archives/lynx/tarballs/${PKG_NAME}${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ncurses slang gnutls"
PKG_LONGDESC="A curses based web browser."

# 🔥 CONFIGURAÇÃO OTIMIZADA PARA CROSS-COMPILE
PKG_CONFIGURE_OPTS_TARGET+=" --with-gnutls \
                             --with-ssl \
                             --with-screen=ncursesw \
                             --enable-widec \
                             --with-pkg-config \
                             --disable-full-paths"

pre_configure_target() {
  cd ${PKG_BUILD}

  # 1. Limpa o BOM (caractere invisível)
  find . -type f \( -name "*.h" -o -name "*.c" \) -exec sed -i '1s/^\xef\xbb\xbf//' {} +

  # 2. Ajuda o Lynx a encontrar o ncursesw sem quebrar o compilador
  # Usamos variáveis de cache do configure para "pular" testes que falham no cross-compile
  export cf_cv_ncurses_header="ncursesw/ncurses.h"
  export cf_cv_ncurses_version="6.1"

  # 3. Vacina GCC 15: Lynx tem funções antigas que o GCC 15 não gosta
  export CFLAGS="$CFLAGS -Wno-implicit-function-declaration -Wno-int-conversion -fcommon"
}
