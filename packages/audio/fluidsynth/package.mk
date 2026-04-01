# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="fluidsynth"
PKG_VERSION="2.5.3"
PKG_SHA256="6f247edfb4b91b927efc68c8884cec2ec345c8007afe6b59558cc52a67ef2517"
PKG_LICENSE="GPL"
PKG_SITE="http://fluidsynth.org/"
PKG_URL="https://github.com/FluidSynth/fluidsynth/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain glib libsndfile gcem"
PKG_LONGDESC="FluidSynth renders midi music files as raw audio data, for playing or conversion."
PKG_BUILD_FLAGS="+pic"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=0 \
                       -DLIB_SUFFIX= \
                       -Denable-libsndfile=1 \
                       -Denable-pkgconfig=1 \
                       -Denable-pulseaudio=0 \
					   -Denable-systemd=1 \
                       -Denable-readline=0"

pre_configure_target() {
  if [[ "$PROJECT" == "Amlogic-ng" ]]; then
    PKG_CMAKE_OPTS_TARGET="$PKG_CMAKE_OPTS_TARGET -Denable-systemd=1"
  elif [[ "$PROJECT" == "Amlogic" ]]; then
    PKG_CMAKE_OPTS_TARGET="$PKG_CMAKE_OPTS_TARGET -Denable-systemd=0"
  else
    PKG_CMAKE_OPTS_TARGET="$PKG_CMAKE_OPTS_TARGET -Denable-systemd=0"
  fi
}
