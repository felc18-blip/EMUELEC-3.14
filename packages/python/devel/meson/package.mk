# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2018-present EmuELEC (https://www.emuelec.org)

PKG_NAME="meson"
PKG_VERSION="1.8.2"
PKG_SHA256="c105816d8158c76b72adcb9ff60297719096da7d07f6b1f000fd8c013cd387af"
PKG_LICENSE="Apache"
PKG_SITE="https://mesonbuild.com"
PKG_URL="https://github.com/mesonbuild/meson/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="Python3:host setuptools:host"
PKG_LONGDESC="High productivity build system"
PKG_TOOLCHAIN="manual"

make_host() {
  # Compilação manual do Meson via setup.py conforme padrão EmuELEC
  python3 setup.py build
}

makeinstall_host() {
  # Instalação no diretório de ferramentas (TOOLCHAIN)
  exec_thread_safe python3 setup.py install --prefix=${TOOLCHAIN} --skip-build

  # AJUSTE PADRÃO EmuELEC:
  # Corrige o caminho do Python no executável para evitar erro de 'path too long'
  # Isso substitui o caminho absoluto pelo uso do /usr/bin/env
  if [ -f "${TOOLCHAIN}/bin/meson" ]; then
    sed -e '1 s/^#!.*$/#!\/usr\/bin\/env python3/' -i ${TOOLCHAIN}/bin/meson
  fi
}