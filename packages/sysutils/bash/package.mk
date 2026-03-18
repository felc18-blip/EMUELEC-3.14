# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team CoreELEC (https://coreelec.org)

PKG_NAME="bash"
PKG_VERSION="5.2.21"
PKG_LICENSE="GPL"
PKG_SITE="http://www.gnu.org/software/bash/"
PKG_URL="http://ftp.gnu.org/gnu/bash/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ncurses readline"
PKG_LONGDESC="Bash is the GNU Project shell - the Bourne Again SHell."
PKG_NEED_UNPACK="$(get_pkg_directory busybox)"

PKG_CONFIGURE_OPTS_TARGET="--with-curses \
                           --without-bash-malloc \
                           --with-installed-readline \
                             bash_cv_getcwd_malloc=yes \
                             bash_cv_printf_a_format=yes \
                             bash_cv_func_sigsetjmp=present \
                             bash_cv_sys_named_pipes=present"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp bash  ${INSTALL}/usr/bin
}

post_makeinstall_target() {
  ln -sf /usr/bin/bash ${INSTALL}/usr/bin/sh
}
