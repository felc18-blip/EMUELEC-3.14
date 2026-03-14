# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="scummvmsa"
PKG_VERSION="2.9.1"
PKG_REV="1"
PKG_LICENSE="GPL2"
PKG_SITE="https://github.com/scummvm/scummvm"
PKG_URL="${PKG_SITE}/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_net freetype fluidsynth-git libmad timidity"
PKG_SHORTDESC="Script Creation Utility for Maniac Mansion Virtual Machine"
PKG_LONGDESC="ScummVM is a program which allows you to run certain classic graphical point-and-click adventure games, provided you already have their data files."

pre_configure_target() {
  # Entra na pasta de build
  cd ${PKG_BUILD}

  # MARRETA: Caminho corrigido para a versão 2.9.1 (audio/softsynth/fluidsynth.cpp)
  # Adicionei um "|| true" e testei dois caminhos comuns só por garantia
  sed -i '/fluid_synth_set_chorus_group_nr/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || \
  sed -i '/fluid_synth_set_chorus_group_nr/,/);/d' audio/softsynths/fluidsynth.cpp 2>/dev/null || true
  
  sed -i '/fluid_synth_set_chorus_group_level/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_set_chorus_group_speed/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_set_chorus_group_depth/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_set_chorus_group_type/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_set_reverb_group_roomsize/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_set_reverb_group_damp/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_set_reverb_group_width/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_set_reverb_group_level/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_chorus_on/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_reverb_on/,/);/d' audio/softsynth/fluidsynth.cpp 2>/dev/null || true

  TARGET_CONFIGURE_OPTS="--disable-opengl-game \
                         --disable-opengl-game-classic \
                         --disable-opengl-game-shaders \
                         --host=${TARGET_NAME} \
                         --backend=sdl \
                         --enable-vkeybd \
                         --enable-optimizations \
                         --opengl-mode=gles2 \
                         --with-sdl-prefix=${SYSROOT_PREFIX}/usr \
                         --disable-debug \
                         --enable-release \
                         --enable-engine=xeen \
                         --enable-engine=mm \
                         --enable-engine=adl,testbed,scumm,scumm_7_8,grim,monkey4,mohawk,myst,riven,sci32,agos2,sword2,drascula,sky,lure,queen,testbed,director,stark \
                         --prefix=/usr/local"

  ./configure ${TARGET_CONFIGURE_OPTS}
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