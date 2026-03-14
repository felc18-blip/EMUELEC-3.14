# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert

PKG_NAME="fbterm"
PKG_VERSION="ef9a13146e24c059fa44151e2a0a22b9762853bc"
PKG_SHA256="149c9fd243b6f93a0e907c8adf281e6e308d15be6a30fc0b1081755c0bc44dbc"
PKG_LICENSE="GPLv2+"
PKG_SITE="https://github.com/sfzhi/fbterm"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain freetype fontconfig libiconv"

PKG_LONGDESC="fbterm is a framebuffer based terminal emulator for linux"

PKG_TOOLCHAIN="configure"

# força link com libiconv
PKG_MAKE_OPTS_TARGET+=" LIBS=-liconv"

pre_configure_target() {
  cd ..
  rm -rf .${TARGET_NAME}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/src/fbterm ${INSTALL}/usr/bin/

  mkdir -p ${INSTALL}/usr/share/terminfo
  tic ${PKG_BUILD}/terminfo/fbterm -o ${INSTALL}/usr/share/terminfo
}

