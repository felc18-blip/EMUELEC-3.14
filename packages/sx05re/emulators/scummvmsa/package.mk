# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="scummvmsa"
PKG_VERSION="2026.2.0"
PKG_REV="1"
PKG_LICENSE="GPL2"
PKG_SITE="https://github.com/scummvm/scummvm"
PKG_URL="${PKG_SITE}/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL3 SDL3_net freetype fluidsynth soundfont-generaluser alsa-lib"
PKG_LONGDESC="Script Creation Utility for Maniac Mansion Virtual Machine"

pre_configure_target() {
  # scummvm 2026.2.0 ja tem suporte SDL3 nativo no configure (-DUSE_SDL3=1).
  # Sysroot tem sdl12_compat/sdl2-compat .pc files que confundem o autodetect,
  # entao forcar a deteccao SDL3 via 2 seds:
  # 1) zerar lista de sdl-configs (nada de sdl2-config) -> fallback pkg-config sdl3
  # 2) curto-circuitar `--exists sdl || --exists sdl2` pra cair no elif sdl3
  sed -i 's|^\tsdlconfigs=".*"|\tsdlconfigs=""|' ${PKG_BUILD}/configure
  sed -i 's|(\$_pkgconfig --exists sdl \|\| \$_pkgconfig --exists sdl2)|false|' \
    ${PKG_BUILD}/configure

  TARGET_CONFIGURE_OPTS="--host=${TARGET_NAME} --backend=sdl --enable-alsa --disable-debug --enable-release --enable-vkeybd --opengl-mode=gles2 --enable-optimizations"
}

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/config/scummvm/
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/scummvm/
  chmod 0755 ${INSTALL}/usr/config/scummvm/games/*sh

  mkdir -p ${INSTALL}/usr/config/scummvm/themes
  cp -rf ${PKG_BUILD}/gui/themes ${INSTALL}/usr/config/scummvm/themes

  mv ${INSTALL}/usr/local/bin ${INSTALL}/usr/
  cp -rf ${PKG_DIR}/sources/* ${INSTALL}/usr/bin
  chmod 755 ${INSTALL}/usr/bin/*

  for i in appdata applications doc icons man; do
    rm -rf "${INSTALL}/usr/local/share/${i}"
  done
}
