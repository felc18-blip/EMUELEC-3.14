PKG_NAME="SDL3_mixer"
PKG_VERSION="3.2.0"
PKG_LICENSE="ZLIB"
PKG_SITE="https://github.com/libsdl-org/SDL_mixer"
PKG_URL="${PKG_SITE}/archive/refs/tags/release-${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="SDL3_mixer-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain alsa-lib SDL3 mpg123 libvorbis libogg opusfile libmodplug flac"
PKG_DEPENDS_HOST="toolchain:host"

PKG_TOOLCHAIN="cmake"

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
}
