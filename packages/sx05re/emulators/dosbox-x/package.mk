# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="dosbox-x"

# NextOS: unifica versao. O commit antigo p/ Amlogic-old (286e859e) tinha
# acinclude.m4 desalinhado — patch 001-sdl-config falhava (Hunk #1 FAILED).
# O commit unificado abaixo tem o acinclude.m4 atual, que casa com o patch.
PKG_VERSION="5e7f129f43683a0dd5a797d29b962a429d9bd0a7"
PKG_SHA256="edf31acd6310157a6617f9f25e2c99a39f40bcdffa6da3aeb78a0ed3db5655dc"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/joncampbell123/dosbox-x"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain linux glibc glib systemd dbus alsa-lib SDL2 SDL2_net SDL_sound libpng zlib libvorbis flac libogg fluidsynth-git munt"
PKG_LONGDESC="DOSBox-X fork of the DOSBox project."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="+lto"

pre_configure_target() {
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}

  # NextOS: forca sysroot sdl2-config (acinclude.m4 do commit unificado roda
  # AC_PATH_PROG que pega /usr/bin/sdl2-config do HOST se nao definirmos).
  # Tambem desabilita pkg-config pra evitar fallback no host pkg-config.
  export SDL2_CONFIG="${SYSROOT_PREFIX}/usr/bin/sdl2-config"
  export PKG_CONFIG_LIBDIR="${SYSROOT_PREFIX}/usr/lib/pkgconfig:${SYSROOT_PREFIX}/usr/share/pkgconfig"

  PKG_CONFIGURE_OPTS_TARGET="--prefix=/usr \
                             --enable-core-inline \
                             --enable-dynrec \
                             --enable-unaligned_memory \
                             --disable-sdl \
                             --enable-sdl2 \
                             --enable-mt32 \
                             --with-sdl2-prefix=${SYSROOT_PREFIX}/usr"
}

pre_make_target() {
  # Define DOSBox version
  sed -e "s/SVN/SDL2/" -i ${PKG_BUILD}/config.h

# NextOS: RetroWaveLib inclui <linux/gpio.h> incondicionalmente. Copiamos
# o header local p/ todos os devices (kernel 3.14 do Amlogic-old nao tem).
cp -f ${PKG_DIR}/include/gpio.h ${SYSROOT_PREFIX}/usr/include/linux/

# NextOS: kernel 3.14 spidev.h nao tem SPI_IOC_WR_MODE32/RD_MODE32 (3.15+).
# Injeta defensive defines no topo do Linux_SPI.c (no-op em kernels mais novos).
SPI_FILE="${PKG_BUILD}/src/hardware/RetroWaveLib/Platform/Linux_SPI.c"
if [ -f "$SPI_FILE" ] && ! grep -q "NEXTOS_SPI_COMPAT" "$SPI_FILE"; then
  sed -i '1i\
/* NEXTOS_SPI_COMPAT: kernel 3.14 spidev.h carece WR_MODE32/RD_MODE32 */\
#include <linux/spi/spidev.h>\
#ifndef SPI_IOC_WR_MODE32\
#define SPI_IOC_WR_MODE32 _IOW(SPI_IOC_MAGIC, 5, __u32)\
#endif\
#ifndef SPI_IOC_RD_MODE32\
#define SPI_IOC_RD_MODE32 _IOR(SPI_IOC_MAGIC, 5, __u32)\
#endif' "$SPI_FILE"
fi

}

post_makeinstall_target() {
  # Create config directory & install config
  mkdir -p ${INSTALL}/usr/config/emuelec/configs/dosbox-x/
  cp -a ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
  cp -a ${PKG_DIR}/config/*  ${INSTALL}/usr/config/emuelec/configs/dosbox-x/
  
# NextOS: limpa o gpio.h injetado em pre_make_target (todos os devices)
rm -f ${TOOLCHAIN}/${TARGET_NAME}/sysroot/usr/include/linux/gpio.h
}
