# SPDX-License-Identifier: GPL-2.0-or-later
#
# lib32-SDL2_mixer: versao 2.8.0 via CMake, espelhando a aarch64.
# Compila contra lib32-SDL2 (sdl2-compat) e instala em /usr/lib32.

PKG_NAME="lib32-SDL2_mixer"
PKG_VERSION="2.8.0"
PKG_LICENSE="ZLIB"
PKG_SITE="https://github.com/libsdl-org/SDL_mixer"
PKG_URL="${PKG_SITE}/archive/refs/tags/release-${PKG_VERSION}.tar.gz"
PKG_ARCH="aarch64"
PKG_DEPENDS_TARGET="lib32-toolchain lib32-alsa-lib lib32-SDL2 lib32-mpg123-compat lib32-libvorbis lib32-libogg lib32-opusfile lib32-libmodplug lib32-flac"
PKG_DEPENDS_HOST="toolchain:host SDL2:host"
PKG_LONGDESC="SDL_mixer 2.8.0 (lib32)"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="lib32"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DSDL2MIXER_MIDI_FLUIDSYNTH=OFF \
                         -DSDL2MIXER_FLAC=ON \
                         -DSDL2MIXER_MOD_MODPLUG=ON \
                         -DSDL2MIXER_VORBIS_TREMOR=ON \
                         -DSDL2MIXER_OGG=ON \
                         -DSDL2MIXER_MP3=ON \
                         -DSDL2MIXER_SAMPLES=OFF \
                         -DSDL2MIXER_MOD_MODPLUG_SHARED=OFF \
                         -DSDL2MIXER_MOD_XMP=OFF \
                         -DSDL2MIXER_WAVPACK=OFF"

  # Fix: impede CMake de pegar libSDL2.so do toolchain host (64-bit)
  # quando o build eh 32-bit. Forca paths do sysroot 32-bit.
  export SDL2_DIR="${SYSROOT_PREFIX}/usr/lib/cmake/SDL2"
  export PKG_CONFIG_LIBDIR="${SYSROOT_PREFIX}/usr/lib/pkgconfig:${SYSROOT_PREFIX}/usr/share/pkgconfig"
  export PKG_CONFIG_SYSROOT_DIR="${SYSROOT_PREFIX}"
  export LDFLAGS="$(echo ${LDFLAGS} | sed "s|-L${TOOLCHAIN}/lib[[:space:]]*||g")"
}

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/include
  safe_remove ${INSTALL}/usr/share
  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}
