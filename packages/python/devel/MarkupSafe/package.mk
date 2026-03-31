# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2014 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="MarkupSafe"
PKG_VERSION="3.0.2"
PKG_SHA256="ee55d3edf80167e48ea11a923c7386f4669df67d7994554387f84e7d8b0a2bf0"
PKG_LICENSE="GPL"
PKG_SITE="https://pypi.org/project/MarkupSafe/"
# No 3.0.2 o nome no PyPI mudou para minúsculas no tar.gz
PKG_URL="https://files.pythonhosted.org/packages/source/m/markupsafe/markupsafe-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="Python3:host setuptools:host"
PKG_LONGDESC="MarkupSafe implements a XML/HTML/XHTML Markup safe string for Python"
PKG_TOOLCHAIN="manual"

make_host() {
  ${TOOLCHAIN}/bin/python3 setup.py build
}

make_target() {
  ${TOOLCHAIN}/bin/python3 setup.py build
}

makeinstall_host() {
  # Usamos --old-and-unmanageable para ignorar a falta do distutils/pip
  ${TOOLCHAIN}/bin/python3 setup.py install --prefix=${TOOLCHAIN} --old-and-unmanageable
}

makeinstall_target() {
  # Instala na imagem final do NextOS-Elite
  ${TOOLCHAIN}/bin/python3 setup.py install --prefix=${INSTALL}/usr --old-and-unmanageable
}