PKG_NAME="bash"
PKG_VERSION="5.2.21"
PKG_LICENSE="GPL"
PKG_SITE="http://www.gnu.org/software/bash/"
PKG_URL="http://ftp.gnu.org/gnu/bash/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ncurses readline"
PKG_LONGDESC="The GNU Bourne Again shell."

PKG_CONFIGURE_OPTS_TARGET="--with-curses \
                           --without-bash-malloc \
                           bash_cv_getcwd_malloc=yes \
                           bash_cv_printf_a_format=yes \
                           bash_cv_func_sigsetjmp=present \
                           bash_cv_sys_named_pipes=present"

pre_configure_target() {
  export CPPFLAGS="-I${SYSROOT_PREFIX}/usr/include/ncursesw"
  export LDFLAGS="-lncursesw -ltinfow"
}

post_install() {
  ln -sf bash ${INSTALL}/usr/bin/sh
  mkdir -p ${INSTALL}/etc
  cat <<EOF >${INSTALL}/etc/shells
/usr/bin/bash
/usr/bin/sh
EOF
  chmod 4755 ${INSTALL}/usr/bin/bash
}