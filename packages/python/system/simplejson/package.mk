# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="simplejson"
PKG_VERSION="3.20.1"
PKG_SHA256="e64139b4ec4f1f24c142ff7dcafe55a22b811a74d86d66560c8815687143037d"
PKG_LICENSE="OSS"
PKG_SITE="http://pypi.org/project/simplejson"
PKG_URL="https://files.pythonhosted.org/packages/source/${PKG_NAME:0:1}/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python3 distutilscross:host"
PKG_LONGDESC="A simple, fast, complete, correct and extensible JSON encoder and decoder for Python 2.5+."
PKG_TOOLCHAIN="manual"

pre_make_target() {
  export PYTHONXCPREFIX="${SYSROOT_PREFIX}/usr"
}

make_target() {
  python3 setup.py build
}

makeinstall_target() {
  python3 setup.py install --root=${INSTALL} --prefix=/usr
}

post_makeinstall_target() {
  python_remove_source
  rm -rf ${INSTALL}/usr/lib/python*/site-packages/*/tests
}