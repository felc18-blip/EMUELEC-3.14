# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)
# Adaptado para NextOS-Elite-Edition / EmuELEC Base

PKG_NAME="Python3"
PKG_VERSION="3.14.3"
PKG_SHA256="a97d5549e9ad81fe17159ed02c68774ad5d266c72f8d9a0b5a9c371fe85d902b"
PKG_LICENSE="OSS"
PKG_SITE="https://www.python.org/"
PKG_URL="https://www.python.org/ftp/python/${PKG_VERSION}/${PKG_NAME::-1}-${PKG_VERSION}.tar.xz"

# ATENÇÃO: Python 3.14 exige 'mpdecimal' como dependência. 
# Você precisará ter o package do 'mpdecimal' no seu sistema no futuro.
PKG_DEPENDS_HOST="zlib:host bzip2:host libffi:host mpdecimal:host util-linux:host autoconf-archive:host openssl:host"
PKG_DEPENDS_TARGET="autotools:host gcc:host toolchain Python3:host sqlite expat zlib bzip2 xz openssl libffi readline mpdecimal ncurses util-linux"
PKG_LONGDESC="Python3 is an interpreted object-oriented programming language."
PKG_BUILD_FLAGS="-cfg-libs -cfg-libs:host"
PKG_TOOLCHAIN="autotools"

PKG_PYTHON_VERSION="python3.14"

# Módulos desativados padrão do EmuELEC (bsddb não existe mais no 3.14)
PKG_PY_DISABLED_MODULES="_tkinter nis gdbm ossaudiodev"

# Na versão 3.13+, o Python mudou de --disable-MODULO para variáveis ac_cv e py_cv_module
PKG_CONFIGURE_OPTS_HOST="ac_cv_prog_HAS_HG=/bin/false
                         ac_cv_prog_SVNVERSION=/bin/false
                         py_cv_module_unicodedata=yes
                         py_cv_module__bz2=n/a
                         py_cv_module__codecs_cn=n/a
                         py_cv_module__codecs_hk=n/a
                         py_cv_module__codecs_iso2022=n/a
                         py_cv_module__codecs_jp=n/a
                         py_cv_module__codecs_kr=n/a
                         py_cv_module__codecs_tw=n/a
                         py_cv_module__decimal=n/a
                         py_cv_module__lzma=n/a
                         py_cv_module_nis=n/a
                         py_cv_module_ossaudiodev=n/a
                         py_cv_module__dbm=n/a
                         py_cv_module__gdbm=n/a
                         --disable-pyc-build
                         --disable-sqlite3
                         --without-readline
                         --disable-tk
                         --disable-curses
                         --disable-pydoc
                         --disable-test-modules
                         --disable-idle3
                         --with-expat=builtin
                         --with-doc-strings
                         --without-pymalloc
                         --with-ensurepip=no
                         --enable-shared
"

PKG_CONFIGURE_OPTS_TARGET="ac_cv_prog_HAS_HG=/bin/false
                           ac_cv_prog_SVNVERSION=/bin/false
                           ac_cv_file__dev_ptmx=no
                           ac_cv_file__dev_ptc=no
                           ac_cv_have_long_long_format=yes
                           ac_cv_working_tzset=yes
                           ac_cv_func_lchflags_works=no
                           ac_cv_func_chflags_works=no
                           ac_cv_func_printf_zd=yes
                           ac_cv_buggy_getaddrinfo=no
                           ac_cv_header_bluetooth_bluetooth_h=no
                           ac_cv_header_bluetooth_h=no
                           py_cv_module_unicodedata=yes
                           py_cv_module__codecs_cn=n/a
                           py_cv_module__codecs_hk=n/a
                           py_cv_module__codecs_iso2022=n/a
                           py_cv_module__codecs_jp=n/a
                           py_cv_module__codecs_kr=n/a
                           py_cv_module__codecs_tw=n/a
                           py_cv_module__decimal=n/a
                           py_cv_module_nis=n/a
                           py_cv_module_ossaudiodev=n/a
                           py_cv_module__dbm=n/a
                           --disable-pyc-build
                           --enable-sqlite3
                           --with-readline
                           --disable-tk
                           --enable-curses
                           --disable-pydoc
                           --disable-test-modules
                           --disable-idle3
                           --with-expat=system
                           --with-doc-strings
                           --with-lto
                           --without-pymalloc
                           --without-ensurepip
                           --enable-ipv6
                           --with-build-python=${TOOLCHAIN}/bin/python
                           --enable-shared
"

pre_configure_host() {
  export PYTHON_MODULES_INCLUDE="${HOST_INCDIR}"
  export PYTHON_MODULES_LIB="${HOST_LIBDIR}"
  export DISABLED_EXTENSIONS="readline _curses _curses_panel ${PKG_PY_DISABLED_MODULES}"
  export DONT_BUILD_LEGACY_PYC=1
}

post_make_host() {
  sed -e "s|^ 'LIBDIR':.*| 'LIBDIR': '/usr/lib',|g" -i $(find ${PKG_BUILD}/.${HOST_NAME} -not -path '*/__pycache__/*' -name '_sysconfigdata__*.py')
}

post_makeinstall_host() {
  ln -sf ${PKG_PYTHON_VERSION} ${TOOLCHAIN}/bin/python
  
  # smtpd.py foi removido do Python 3.12+, o -f evita erros se não existir
  rm -f ${TOOLCHAIN}/bin/smtpd.py*
  rm -f ${TOOLCHAIN}/bin/pyvenv
  rm -f ${TOOLCHAIN}/bin/pydoc*

  rm -fr ${PKG_BUILD}/.${HOST_NAME}/build/temp.*

  # reindent.py ainda pode ser útil para o EmuELEC
  if [ -f ${PKG_BUILD}/Tools/scripts/reindent.py ]; then
    cp ${PKG_BUILD}/Tools/scripts/reindent.py ${TOOLCHAIN}/lib/${PKG_PYTHON_VERSION}/
  fi
}

post_make_target() {
  # Fix vital introduzido pelo LibreELEC para cross-compiling avançado no 3.14
  PKG_SYSCONFIG_FILE=$(find ${PKG_BUILD}/.${TARGET_NAME} -not -path '*/__pycache__/*' -name '_sysconfigdata__*.py')
  sed -e "s,\([\'|\ ]\)/usr/include,\1${SYSROOT_PREFIX}/usr/include,g" -i ${PKG_SYSCONFIG_FILE}
  sed -e "s,\([\'|\ ]\)/usr/lib,\1${SYSROOT_PREFIX}/usr/lib,g" -i ${PKG_SYSCONFIG_FILE}
}

pre_configure_target() {
  export PYTHON_MODULES_INCLUDE="${TARGET_INCDIR}"
  export PYTHON_MODULES_LIB="${TARGET_LIBDIR}"
  export DISABLED_EXTENSIONS="${PKG_PY_DISABLED_MODULES}"
  export PKG_CONFIG_PATH="$(get_install_dir xz)/usr/lib/pkgconfig:${PKG_CONFIG_PATH}"
}

post_makeinstall_target() {
  ln -sf ${PKG_PYTHON_VERSION} ${INSTALL}/usr/bin/python

  rm -fr ${PKG_BUILD}/.${TARGET_NAME}/build/temp.*

  PKG_INSTALL_PATH_LIB=${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}

  # lib2to3 foi removido do Python 3.13, ajustado para não quebrar o EmuELEC
  for dir in config compiler sysconfigdata lib-dynload/sysconfigdata test; do
    rm -rf ${PKG_INSTALL_PATH_LIB}/${dir}
  done

  rm -rf ${PKG_INSTALL_PATH_LIB}/distutils/command/*.exe
  rm -rf ${INSTALL}/usr/bin/pyvenv
  rm -rf ${INSTALL}/usr/bin/python*-config
  rm -rf ${INSTALL}/usr/bin/smtpd.py ${INSTALL}/usr/bin/smtpd.py.*

  find ${INSTALL} -name '*.o' -delete

  python_compile ${PKG_INSTALL_PATH_LIB}

  # strip do EmuELEC
  chmod u+w ${INSTALL}/usr/lib/libpython*.so.*
  debug_strip ${INSTALL}/usr
}