# SPDX-License-Identifier: GPL-2.0-only

PKG_NAME="glad"
PKG_VERSION="2.0.8"
PKG_SHA256="44f06f9195427c7017f5028d0894f57eb216b0a8f7c4eda7ce883732aeb2d0fc"
PKG_LICENSE="MIT"
PKG_SITE="https://glad.dav1d.de"
PKG_URL="https://github.com/Dav1dde/glad/archive/refs/tags/v${PKG_VERSION}.tar.gz"

PKG_TOOLCHAIN="manual"
PKG_DEPENDS_HOST="toolchain:host"

make_host() {
  true
}

makeinstall_host() {
  GLAD_PATH=${TOOLCHAIN}/lib/glad

  mkdir -p ${GLAD_PATH}
  cp -rf ${PKG_BUILD}/glad/* ${GLAD_PATH}/

  mkdir -p ${TOOLCHAIN}/bin

  cat > ${TOOLCHAIN}/bin/glad << EOF
#!/usr/bin/env python3
import sys
sys.path.append('${GLAD_PATH}')
from glad.__main__ import main
if __name__ == '__main__':
    main()
EOF

  chmod +x ${TOOLCHAIN}/bin/glad
}
