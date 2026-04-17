# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="lib32-cairo"
PKG_VERSION="$(get_pkg_version cairo)"
PKG_NEED_UNPACK="$(get_pkg_directory cairo)"
PKG_ARCH="aarch64"
PKG_LICENSE="LGPL"
PKG_SITE="http://cairographics.org/"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-zlib lib32-freetype lib32-fontconfig lib32-glib lib32-libpng lib32-pixman"
PKG_PATCH_DIRS+=" $(get_pkg_directory cairo)/patches"
PKG_LONGDESC="Cairo is a vector graphics library with cross-device output support."
PKG_TOOLCHAIN="meson"
PKG_BUILD_FLAGS="lib32"

################################################################################
# FIXES (mantido do seu)
################################################################################

pre_configure_target() {
  # Fix C23 / GCC 15
  find ${PKG_BUILD} -name "pdiff.h" -exec sed -i 's|typedef int bool;||g' {} +
  find ${PKG_BUILD} -name "pdiff.h" -exec sed -i '1i #include <stdbool.h>' {} +
  find ${PKG_BUILD} -name "pdiff.c" -exec sed -i '1i #include <stdbool.h>' {} +

  export CFLAGS="${CFLAGS} -std=gnu11 -Wno-implicit-function-declaration"

  PKG_MESON_OPTS_TARGET="-Ddefault_library=shared \
                        -Dtests=disabled \
                        -Dgtk_doc=false \
                        -Dpng=enabled \
                        -Dzlib=enabled \
                        -Dfreetype=enabled \
                        -Dfontconfig=enabled \
                        -Dglib=enabled \
                        -Dsymbol-lookup=disabled \
                        -Dtee=disabled \
                        -Dxcb=disabled \
                        -Dxlib-xcb=disabled \
                        -Dquartz=disabled \
                        -Dspectre=disabled \
                        -Dxlib=disabled"
}

################################################################################
# UNPACK (mantido)
################################################################################

unpack() {
  ${SCRIPTS}/get cairo
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/cairo/cairo-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

################################################################################
# PÓS
################################################################################

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/include
  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}
