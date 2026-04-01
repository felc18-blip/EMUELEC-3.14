# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Frank Hartung (supervisedthinking (@) gmail.com)

PKG_NAME="fluidsynth-git"
PKG_VERSION="2.3.4"
PKG_LICENSE="GPL"
PKG_SITE="http://fluidsynth.org/"
PKG_URL="https://github.com/FluidSynth/fluidsynth/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain glib libsndfile"
PKG_LONGDESC="FluidSynth renders midi music files as raw audio data, for playing or conversion."
PKG_BUILD_FLAGS="+pic"

pre_configure_target() {
  # 🔥 FIX GLOBAL CMAKE (inclui subprojetos tipo gentables)
  find $PKG_BUILD -name "CMakeLists.txt" -exec \
    sed -i 's/cmake_minimum_required(VERSION.*/cmake_minimum_required(VERSION 3.5)/' {} \;

  PKG_CMAKE_OPTS_TARGET="-DLIB_SUFFIX= \
                         -Denable-readline=0 \
                         -Denable-oss=0 \
                         -Denable-pulseaudio=1 \
                         -Denable-libsndfile=0 \
                         -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
}

post_makeinstall_target() {
  # Create directories
  mkdir -p ${INSTALL}/etc/fluidsynth
  mkdir -p ${INSTALL}/usr/config/fluidsynth/soundfonts

  # Create symlinks & install config file
  cp -a ${PKG_DIR}/config/* ${INSTALL}/usr/config/fluidsynth/
  ln -s /storage/.config/fluidsynth/fluidsynth.conf ${INSTALL}/etc/fluidsynth/
  echo "Place your SoundFonts here!" >> ${INSTALL}/usr/config/fluidsynth/soundfonts/readme.txt

  # Create symlink to SoundFont
  ln -s /usr/share/soundfonts/GeneralUser.sf2  ${INSTALL}/usr/config/fluidsynth/soundfonts/
}
