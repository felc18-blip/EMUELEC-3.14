# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="readline"
PKG_VERSION="8.2"
PKG_SHA256="3feb7171f16a84ee82ca18a36d7b9be109a52c04f492a053331d7d1095007c35"
PKG_LICENSE="MIT"
PKG_SITE="http://www.gnu.org/software/readline/"
PKG_URL="http://ftpmirror.gnu.org/readline/${PKG_NAME}-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain ncurses"

PKG_LONGDESC="The GNU Readline library provides line-editing features."
PKG_BUILD_FLAGS="+pic"

# ✔ static only (igual original EmuELEC)
PKG_CONFIGURE_OPTS_TARGET="bash_cv_wcwidth_broken=no \
                           --disable-shared \
                           --enable-static \
                           --with-curses"

post_makeinstall_target() {
  # ✔ garante uso do ncurses wide (SEM tinfo separado)
  sed -i 's/-lreadline/-lreadline -lncursesw/' \
    ${SYSROOT_PREFIX}/usr/lib/pkgconfig/readline.pc

  # limpa arquivos desnecessários
  rm -rf ${INSTALL}/usr/share/readline
}