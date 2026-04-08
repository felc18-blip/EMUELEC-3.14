PKG_NAME="SDL2_mixer"
PKG_VERSION="2.8.0"
PKG_LICENSE="ZLIB"
PKG_SITE="https://github.com/libsdl-org/SDL_mixer"
PKG_URL="${PKG_SITE}/archive/refs/tags/release-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain alsa-lib SDL2 mpg123 libvorbis libogg opusfile libmodplug flac"
PKG_DEPENDS_HOST="toolchain:host SDL2:host"

PKG_TOOLCHAIN="cmake"

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
}
