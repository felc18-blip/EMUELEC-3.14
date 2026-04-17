# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="cairo"
PKG_VERSION="1.18.4"
PKG_SHA256="445ed8208a6e4823de1226a74ca319d3600e83f6369f99b14265006599c32ccb"
PKG_LICENSE="LGPL"
PKG_SITE="https://cairographics.org/"
PKG_URL="https://cairographics.org/releases/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain zlib freetype fontconfig glib libpng pixman"
PKG_LONGDESC="Cairo is a vector graphics library with cross-device output support."
PKG_TOOLCHAIN="meson"

configure_package() {
  if [ "${DISPLAYSERVER}" = "x11" ]; then
    PKG_DEPENDS_TARGET+=" libXrender libX11 mesa"
  fi

  if [ "${OPENGL_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGL}"
  elif [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  fi
}

pre_configure_target() {
  export CFLAGS="$CFLAGS -std=gnu11 -fcommon -Wno-error"

  PKG_MESON_OPTS_TARGET="\
    -Ddefault_library=shared \
    -Dgtk_doc=false \
    -Dtests=disabled \
    -Dglib=enabled \
    -Dzlib=enabled \
    -Dpng=enabled \
    -Dfreetype=enabled \
    -Dfontconfig=enabled \
    -Dtee=disabled \
    -Dspectre=disabled \
    -Dsymbol-lookup=disabled \
    -Dxcb=disabled \
    -Dxlib-xcb=disabled \
    -Dquartz=disabled \
    -Ddwrite=disabled"

  if [ "${DISPLAYSERVER}" = "x11" ]; then
    PKG_MESON_OPTS_TARGET+=" -Dxlib=enabled"
  else
    PKG_MESON_OPTS_TARGET+=" -Dxlib=disabled"
  fi
}

post_configure_target() {
  # mantém padrão LibreELEC / EmuELEC
  :
}
