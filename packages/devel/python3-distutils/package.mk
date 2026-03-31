# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="python3-distutils"
PKG_VERSION="1.0"
PKG_LICENSE="MIT"
PKG_SITE="local"
PKG_DEPENDS_HOST="Python3:host setuptools:host"
PKG_SECTION="devel"
PKG_SHORTDESC="Restore distutils for Python 3.12+"

PKG_TOOLCHAIN="manual"

makeinstall_host() {

  SITE_PACKAGES=$(${TOOLCHAIN}/bin/python3 -c "import site; print(site.getsitepackages()[0])")

  mkdir -p ${SITE_PACKAGES}/distutils

  cat > ${SITE_PACKAGES}/distutils/__init__.py << 'EOF'
from setuptools._distutils import *
EOF

  cat > ${SITE_PACKAGES}/distutils/cygwinccompiler.py << 'EOF'
from setuptools._distutils.cygwinccompiler import *
EOF
}