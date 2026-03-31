PKG_NAME="pycryptodome"
PKG_VERSION="3.23.0"
PKG_SHA256="5a905f0f4237b79aefee47f3e04568db2ecb70c55dd7cb118974c5260aa9e285"
PKG_LICENSE="BSD"
PKG_SITE="https://pypi.org/project/pycryptodome"
PKG_URL="https://github.com/Legrandin/${PKG_NAME}/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python3 distutilscross:host"
PKG_LONGDESC="PyCryptodome is a self-contained Python package of low-level cryptographic primitives."
PKG_TOOLCHAIN="manual"

pre_configure_target() {
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}

  export PYTHONXCPREFIX="${SYSROOT_PREFIX}/usr"
  export LDSHARED="${CC} -shared"
}

make_target() {
  python3 setup.py build
}

makeinstall_target() {
  python3 setup.py install --root=${INSTALL} --prefix=/usr

  find ${INSTALL} -type d -name SelfTest -exec rm -rf "{}" \; 2>/dev/null || true
  find ${INSTALL} -name SOURCES.txt -exec sed -i "/\/SelfTest\//d;" "{}" \;

  ln -sf Crypto \
    ${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}/site-packages/Cryptodome
}

post_makeinstall_target() {
  python_remove_source
}