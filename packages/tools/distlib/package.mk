# SPDX-License-Identifier: GPL-2.0-only

PKG_NAME="distlib"
PKG_VERSION="0.4.0"
PKG_SHA256="feec40075be03a04501a973d81f633735b4b69f98b05450592310c0f401a4e0d"
PKG_LICENSE="PSF-2.0"
PKG_SITE="https://github.com/pypa/distlib"
PKG_URL="https://files.pythonhosted.org/packages/source/d/distlib/distlib-${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="distlib-${PKG_VERSION}"

PKG_DEPENDS_HOST="Python3:host"
PKG_LONGDESC="Distlib Python packaging library"

PKG_TOOLCHAIN="manual"
PKG_TARGET_ARCH="no"

makeinstall_host() {
  # pega path correto do python
  PYTHON_SITE=$(${TOOLCHAIN}/bin/python3 - <<EOF
import sysconfig
print(sysconfig.get_paths()["purelib"])
EOF
)

  mkdir -p ${PYTHON_SITE}

  # copia a lib diretamente (forma correta)
  cp -r ${PKG_BUILD}/distlib ${PYTHON_SITE}/
}
