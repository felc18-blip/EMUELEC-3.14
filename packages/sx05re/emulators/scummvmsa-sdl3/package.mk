# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS-Elite-Edition: scummvmsa-sdl3 — fork de scummvmsa migrado pra SDL3.
# scummvm 2026.2.0 ja tem suporte SDL3 nativo no configure (-DUSE_SDL3=1);
# basta forcar a deteccao via pkg-config sdl3 e linkar contra SDL3/SDL3_net.

PKG_NAME="scummvmsa-sdl3"
PKG_VERSION="2026.2.0"
PKG_REV="1"
PKG_LICENSE="GPL2"
PKG_SITE="https://github.com/scummvm/scummvm"
PKG_URL="${PKG_SITE}/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="scummvm-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL3 SDL3_net freetype fluidsynth soundfont-generaluser alsa-lib"
PKG_LONGDESC="ScummVM standalone (SDL3 NextOS fork)"

pre_configure_target() {
  # Forcar deteccao SDL3:
  # 1) zerar lista de sdl-configs pra fallback "pkg-config sdl3" funcionar
  # 2) pular o teste "if pkg-config has sdl/sdl2" (sysroot tem
  #    sdl12_compat/sdl2-compat .pc files), forcando elif sdl3.
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
