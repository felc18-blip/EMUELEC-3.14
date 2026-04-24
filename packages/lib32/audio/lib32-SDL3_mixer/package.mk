# SPDX-License-Identifier: GPL-2.0-or-later
#
# lib32-SDL3_mixer: versão 3.2.0 via CMake, espelhando o SDL3_mixer aarch64.
# Compila contra lib32-SDL3 (SDL3 nativo, com driver Mali FBDEV) e instala em
# /usr/lib32. Substitui o lib32-SDL2_mixer no pipeline 32-bit.

PKG_NAME="lib32-SDL3_mixer"
PKG_VERSION="3.2.0"
PKG_LICENSE="ZLIB"
PKG_SITE="https://github.com/libsdl-org/SDL_mixer"
PKG_URL="${PKG_SITE}/archive/refs/tags/release-${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="SDL3_mixer-${PKG_VERSION}.tar.gz"
PKG_ARCH="aarch64"
PKG_DEPENDS_TARGET="lib32-toolchain lib32-alsa-lib lib32-SDL3 lib32-mpg123-compat lib32-libvorbis lib32-libogg lib32-opusfile lib32-libmodplug lib32-flac"
PKG_DEPENDS_HOST="toolchain:host"
PKG_LONGDESC="SDL_mixer 3.2.0 (lib32 — linka contra lib32-SDL3)"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="lib32"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DSDLMIXER_MIDI_FLUIDSYNTH=OFF \
                         -DSDLMIXER_FLAC=ON \
                         -DSDLMIXER_MOD=ON \
                         -DSDLMIXER_MOD_MODPLUG=ON \
                         -DSDLMIXER_MOD_XMP=OFF \
                         -DSDLMIXER_VORBIS=ON \
                         -DSDLMIXER_VORBIS_TREMOR=OFF \
                         -DSDLMIXER_OGG=ON \
                         -DSDLMIXER_MP3=ON \
                         -DSDLMIXER_MP3_MPG123=ON \
                         -DSDLMIXER_SAMPLES=OFF \
                         -DSDLMIXER_TESTS=OFF \
                         -DSDLMIXER_EXAMPLES=OFF \
                         -DSDLMIXER_DEPS_SHARED=OFF \
                         -DSDLMIXER_WAVPACK=OFF \
                         -DSDLMIXER_VENDORED=OFF"

  # Fix: impede CMake de pegar libSDL3.so do toolchain host (64-bit)
  # quando o build é 32-bit. Força paths do sysroot 32-bit.
  export SDL3_DIR="${SYSROOT_PREFIX}/usr/lib/cmake/SDL3"
  export PKG_CONFIG_LIBDIR="${SYSROOT_PREFIX}/usr/lib/pkgconfig:${SYSROOT_PREFIX}/usr/share/pkgconfig"
  export PKG_CONFIG_SYSROOT_DIR="${SYSROOT_PREFIX}"
  export LDFLAGS="$(echo ${LDFLAGS} | sed "s|-L${TOOLCHAIN}/lib[[:space:]]*||g")"
}

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/include
  safe_remove ${INSTALL}/usr/share
  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}
