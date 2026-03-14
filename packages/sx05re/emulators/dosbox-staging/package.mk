# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="dosbox-staging"
PKG_VERSION="3f67c91dd6a998cc091f24d2200e2b99cf37fb18"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/dosbox-staging/dosbox-staging"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain linux meson:host glibc glib systemd dbus alsa-lib SDL2 SDL2_net SDL_sound libpng zlib libvorbis flac libogg fluidsynth munt opusfile"
PKG_LONGDESC="DOS/x86 emulator focusing on ease of use"

# Mantemos sem LTO para evitar as violações de ODR que vimos antes
PKG_BUILD_FLAGS=""

export SSL_CERT_DIR=/etc/ssl/certs

pre_configure_target() {
  PKG_MESON_OPTS_TARGET=" -Duse_opengl=false"

  # A NOVA MARRETA: Apaga as chamadas de função multilinhas que dão erro
  # O comando abaixo localiza a função e apaga ela e os argumentos até o ponto e vírgula
  sed -i '/fluid_synth_set_chorus_group_nr/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_set_chorus_group_level/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_set_chorus_group_speed/,/);/d' ${PKG_BUILD}/target/src/midi/midi_fluidsynth.cpp 2>/dev/null || true
  sed -i '/fluid_synth_set_chorus_group_speed/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_set_chorus_group_depth/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_set_chorus_group_type/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_set_reverb_group_roomsize/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_set_reverb_group_damp/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_set_reverb_group_width/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_set_reverb_group_level/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_chorus_on/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp
  sed -i '/fluid_synth_reverb_on/,/);/d' ${PKG_BUILD}/src/midi/midi_fluidsynth.cpp

  # Suas correções de mouse permanecem
  sed -i "s|C_MANYMOUSE') == true)|C_MANYMOUSE') == false)|" ${PKG_BUILD}/meson.build
  sed -i "s|C_MANYMOUSE', true)|C_MANYMOUSE', false)|" ${PKG_BUILD}/meson.build
}

post_makeinstall_target () {
  mkdir -p ${INSTALL}/usr/config/dosbox
  [ -d "${PKG_DIR}/scripts" ] && cp -a ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
  [ -d "${PKG_DIR}/config" ] && cp -a ${PKG_DIR}/config/* ${INSTALL}/usr/config/dosbox/
  [ -d "${PKG_BUILD}/contrib/resources" ] && cp -a ${PKG_BUILD}/contrib/resources/* ${INSTALL}/usr/config/dosbox/
  
  rm -rf ${INSTALL}/usr/share
  find ${INSTALL}/usr/config/dosbox -name "meson.build" -exec rm -rf {} \;
}