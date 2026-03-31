# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="gptokeyb"
PKG_VERSION="0303b36b5376a9b25cf82a53ed4242509daf14e9"
PKG_ARCH="any"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/EmuELEC/gptokeyb"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain libevdev SDL2 control-gen"
PKG_TOOLCHAIN="manual"
GET_HANDLER_SUPPORT="git"

pre_configure_target() {
  sed -i 's|<SDL.h>|<SDL2/SDL.h>|g' gptokeyb.cpp
}

make_target() {
  # Compilação manual ignorando o Makefile interno
  # A ordem aqui é vital: [Compilador] [Fontes] [Includes] [LDFLAGS] [Bibliotecas]
${CXX} gptokeyb.cpp -o gptokeyb \
  -I${SYSROOT_PREFIX}/usr/include/SDL2 \
  -I${SYSROOT_PREFIX}/usr/include/libevdev-1.0 \
  -L${SYSROOT_PREFIX}/usr/lib \
  -std=c++11 -Wall -O2 \
  -lSDL2 -levdev -lpthread -lrt
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp gptokeyb ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/gptokeyb
  cp -rf ${PKG_BUILD}/configs/*.gptk ${INSTALL}/usr/config/emuelec/configs/gptokeyb
}