# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="viceSA"
PKG_VERSION="3.9"
PKG_ARCH="any"
PKG_LICENSE="GPL2"
PKG_SITE="https://sourceforge.net/projects/vice-emu"
PKG_URL="${PKG_SITE}/files/releases/vice-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain xa:host SDL2 SDL2_image ncurses readline dos2unix:host"

PKG_LONGDESC="VICE emulator collection"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET=" --enable-external-ffmpeg \
                            --disable-option-checking \
                            --enable-midi \
                            --enable-lame \
                            --with-zlib \
                            --with-jpeg \
                            --with-png \
                            --enable-x64 \
                            --enable-sdl2ui \
                            --enable-gtk3ui=no"

pre_configure_target() {
  LDFLAGS="${LDFLAGS} -lSDL2"
  CFLAGS="${CFLAGS} -fcommon"
}

post_makeinstall_target() {

  # cria pasta de config
  mkdir -p ${INSTALL}/usr/config/vice

  # copia configs se existirem
  if [ -d "${PKG_DIR}/configs" ]; then
    cp -f ${PKG_DIR}/configs/* ${INSTALL}/usr/config/vice
  fi

  # cria launchers estilo JELOS
  for sc in x128 x64sc xplus4 xvic; do
    cp -f ${PKG_DIR}/sources/start_vice.sh ${INSTALL}/usr/bin/start_${sc}.sh
    sed -i "s~@EMU@~${sc}~g" ${INSTALL}/usr/bin/start_${sc}.sh
  done

  chmod 0755 ${INSTALL}/usr/bin/start_*.sh
}