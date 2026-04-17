# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="lib32-pixman"
PKG_VERSION="$(get_pkg_version pixman)"
PKG_NEED_UNPACK="$(get_pkg_directory pixman)"
PKG_ARCH="aarch64"
PKG_LICENSE="OSS"
PKG_SITE="http://www.x.org/"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-util-macros"
PKG_PATCH_DIRS+=" $(get_pkg_directory pixman)/patches"
PKG_LONGDESC="Pixman lib32"

PKG_TOOLCHAIN="meson"
PKG_BUILD_FLAGS="lib32"

pre_configure_target() {
  export CFLAGS="${CFLAGS} -Wno-error"
  export CXXFLAGS="${CXXFLAGS} -Wno-error"
}

# 🔥 FLAGS CORRETAS PARA MESON
PKG_MESON_OPTS_TARGET="-Dopenmp=disabled \
  -Dloongson-mmi=disabled \
  -Dmmx=disabled \
  -Dsse2=disabled \
  -Dvmx=disabled \
  -Darm-simd=disabled \
  -Dneon=enabled \
  -Dmips-dspr2=disabled \
  -Dgnu-inline-asm=enabled \
  -Dtimers=false \
  -Dgtk=disabled \
  -Dlibpng=disabled \
  -Dtests=disabled"

unpack() {
  ${SCRIPTS}/get pixman
  mkdir -p ${PKG_BUILD}

  SRC=$(ls ${SOURCES}/pixman/*.tar.* | head -n1)
  tar --strip-components=1 -xf ${SRC} -C ${PKG_BUILD}
}

post_makeinstall_target() {
  cp -f ${SYSROOT_PREFIX}/usr/lib/pkgconfig/pixman-1.pc \
        ${SYSROOT_PREFIX}/usr/lib/pkgconfig/pixman.pc

  cp -rf ${SYSROOT_PREFIX}/usr/include/pixman-1 \
         ${SYSROOT_PREFIX}/usr/include/pixman

  safe_remove ${INSTALL}/usr/include
  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}
