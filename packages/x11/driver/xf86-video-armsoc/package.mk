################################################################################
# NextOS-Elite-Edition - Package Script
# Package: xf86-video-armsoc
################################################################################

PKG_NAME="xf86-video-armsoc"
PKG_VERSION="9b49434883c7c2d86b16854e14a9f89119550f25"
PKG_SITE="https://github.com/superna9999/xf86-video-armsoc"
PKG_URL="https://github.com/superna9999/xf86-video-armsoc.git"
PKG_DEPENDS_TARGET="toolchain xorg-server libdrm"
PKG_SECTION="x11/driver"
PKG_SHORTDESC="X.org libdrm-based driver for Amlogic/Mali"
PKG_LONGDESC="Driver armsoc modificado (superna9999) para chipsets Amlogic."

PKG_TOOLCHAIN="autotools"
PKG_AUTOGEN="yes"
PKG_CONFIGURE_OPTS_EXTRA="--with-xorg-module-dir=/usr/lib/xorg/modules"

# Força o compilador a ignorar os avisos antigos do código
pre_configure_target() {
  export CFLAGS="$CFLAGS -Wno-error"
}

pre_make_target() {
  export LDFLAGS="-lm"
}

post_install_target() {
  mkdir -p ${INSTALL_PATH}/etc/X11/xorg.conf.d
  cp ${PKG_DIR}/scripts/20-armsoc.conf ${INSTALL_PATH}/etc/X11/xorg.conf.d/20-armsoc.conf
}
