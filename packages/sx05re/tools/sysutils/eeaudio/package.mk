# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present EmuELEC (https://github.com/emuelec)

PKG_NAME="eeaudio"
PKG_VERSION="v1"
PKG_LICENSE="Public Domain"
PKG_DEPENDS_TARGET="toolchain"
PKG_SHORTDESC="A workaround used to fix alsa not initializing at boot"
PKG_TOOLCHAIN="manual"

make_target() {
    ${CC} -O2 -DUSE_ALSA -DUSE_SDL -o eeaudio eeaudio.c -lasound `sdl2-config --cflags --libs`
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp eeaudio ${INSTALL}/usr/bin
}
