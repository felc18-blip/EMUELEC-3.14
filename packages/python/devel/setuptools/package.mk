# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="setuptools"
PKG_VERSION="80.9.0"
PKG_SHA256="f36b47402ecde768dbfafc46e8e4207b4360c654f1f3bb84475f0a28628fb19c"
PKG_LICENSE="OSS"
PKG_SITE="https://pypi.org/project/setuptools"
PKG_URL="https://files.pythonhosted.org/packages/source/${PKG_NAME:0:1}/${PKG_NAME}/${PKG_NAME,,}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="Python3:host"
PKG_LONGDESC="Replaces Setuptools as the standard method for working with Python module distributions."
PKG_TOOLCHAIN="manual"

make_host() {
  # No Python 3.14+, pulamos o bootstrap.py pois ele exige distutils (que foi removido).
  # A versão 70.0.0 do setuptools já consegue se auto-buildar com o comando abaixo:
  ${TOOLCHAIN}/bin/python3 setup.py build
}

make_target() {
  # No target (ARM), apenas garantimos que o build ocorra com o Python do host
  ${TOOLCHAIN}/bin/python3 setup.py build
}

makeinstall_host() {
  # Instalamos no Toolchain para que o Meson e outras ferramentas encontrem o pacote.
  # Usamos --old-and-unmanageable para garantir que a instalação seja feita de forma 
  # tradicional sem exigir o 'pip' (que desativamos no Python).
  ${TOOLCHAIN}/bin/python3 setup.py install --prefix=${TOOLCHAIN} --old-and-unmanageable
}

makeinstall_target() {
  # Caso precise dele na imagem final do TV Box (opcional, mas bom ter):
  ${TOOLCHAIN}/bin/python3 setup.py install --prefix=${INSTALL}/usr --old-and-unmanageable
}