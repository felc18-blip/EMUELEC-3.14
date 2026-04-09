# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="TvTextViewer"
PKG_VERSION="fcbda2d1708e9e2c650abc589ea8e7f1fe1d04d8"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/RetroGFX/TvTextViewer"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_SHORTDESC="Full-screen text viewer tool with gamepad controls"
PKG_TOOLCHAIN="make"

pre_configure_target() {
  cd ${PKG_BUILD}

  # Força a inicialização e atualização dos submódulos do Git diretamente na pasta de build
  git submodule update --init --recursive

  sed -i "s|\`sdl2-config|\`${SYSROOT_PREFIX}/usr/bin/sdl2-config|g" Makefile
}

makeinstall_target(){
mkdir -p ${INSTALL}/usr/bin
cp text_viewer ${INSTALL}/usr/bin
}
