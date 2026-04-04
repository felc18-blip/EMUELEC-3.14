# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="gobject-introspection"
PKG_VERSION="1.86.0"
PKG_ARCH="any"
PKG_LICENSE="LGPL"
PKG_SITE="https://gi.readthedocs.io/"
PKG_URL="https://download.gnome.org/sources/gobject-introspection/1.86/gobject-introspection-1.86.0.tar.xz"

PKG_DEPENDS_TARGET="toolchain libffi glib Python3 qemu:host gobject-introspection:host"
PKG_DEPENDS_HOST="libffi:host glib:host Python3:host python3-distutils:host"

PKG_SECTION="devel"
PKG_SHORTDESC="GLib introspection library"
PKG_LONGDESC="GObject Introspection provides a framework for describing APIs and collecting them in a uniform, machine readable format."
PKG_TOOLCHAIN="meson"

pre_configure_host() {

  PKG_MESON_OPTS_HOST=" \
    -Ddoctool=disabled"

  export GI_SCANNER_DISABLE_CACHE="1"

  CC="${HOST_CC}"
  CXX="${HOST_CXX}"
  AR="${HOST_AR}"
  CPP="${HOST_PREFIX}cpp"
  CPPFLAGS="${HOST_CPPFLAGS}"
  CFLAGS="${HOST_CFLAGS} -fPIC"
  LDFLAGS="${HOST_LDFLAGS}"
}

pre_configure_target() {

  export PKG_CONFIG_PATH="${SYSROOT_PREFIX}/usr/lib/pkgconfig"

  GLIBC_DYNAMIC_LINKER="$(ls ${SYSROOT_PREFIX}/usr/lib/ld-linux-*.so.*)"
  QEMU_BINARY="${TOOLCHAIN}/bin/qemu-${TARGET_ARCH}"

  TARGET_LDFLAGS="${TARGET_LDFLAGS} -Wl,--dynamic-linker=${GLIBC_DYNAMIC_LINKER}"

  CC="${TARGET_CC}"
  CXX="${TARGET_CXX}"
  AR="${TARGET_AR}"
  CPP="${TARGET_PREFIX}cpp"
  CPPFLAGS="${TARGET_CPPFLAGS}"
  CFLAGS="${TARGET_CFLAGS} -fPIC"
  LDFLAGS="${TARGET_LDFLAGS}"

  PKG_MESON_OPTS_TARGET=" \
    -Ddoctool=disabled \
    -Dpython=${TOOLCHAIN}/bin/${PKG_PYTHON_VERSION} \
    -Dgi_cross_use_prebuilt_gi=true \
    -Dgi_cross_binary_wrapper=${TOOLCHAIN}/bin/g-ir-scanner-binary-wrapper \
    -Dgi_cross_ldd_wrapper=${TOOLCHAIN}/bin/g-ir-scanner-ldd-wrapper"

  export GI_SCANNER_DISABLE_CACHE="1"

  cat > ${TOOLCHAIN}/bin/g-ir-scanner-binary-wrapper << EOF
#!/bin/sh
${QEMU_BINARY} \
  -E LD_LIBRARY_PATH="${SYSROOT_PREFIX}/usr/lib:${TOOLCHAIN}/${TARGET_NAME}/lib" \
  -L ${SYSROOT_PREFIX}/usr \
  "\$@"
EOF

  cat > ${TOOLCHAIN}/bin/g-ir-scanner-ldd-wrapper << EOF
#!/bin/sh
${QEMU_BINARY} \
  -E LD_LIBRARY_PATH="${SYSROOT_PREFIX}/usr/lib:${TOOLCHAIN}/${TARGET_NAME}/lib" \
  ${GLIBC_DYNAMIC_LINKER} --list "\$1"
EOF

  chmod +x ${TOOLCHAIN}/bin/g-ir-scanner-*-wrapper
}

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/bin
  rm -rf ${INSTALL}/usr/lib/gobject-introspection
  rm -rf ${INSTALL}/usr/share
}
