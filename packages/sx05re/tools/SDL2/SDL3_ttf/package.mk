PKG_NAME="SDL3_ttf"
PKG_VERSION="3.2.2"
PKG_LICENSE="ZLIB"
PKG_SITE="https://github.com/libsdl-org/SDL_ttf"
PKG_URL="${PKG_SITE}/archive/refs/tags/release-${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="SDL3_ttf-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain SDL3 freetype harfbuzz"
PKG_DEPENDS_HOST="toolchain:host"

PKG_TOOLCHAIN="cmake"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DSDLTTF_SAMPLES=OFF \
                         -DSDLTTF_TESTS=OFF \
                         -DSDLTTF_HARFBUZZ=ON \
                         -DSDLTTF_VENDORED=OFF \
                         -DSDLTTF_PLUTOSVG=OFF \
                         -DSDLTTF_BUILD_SHARED_LIBS=ON \
                         -DBUILD_SHARED_LIBS=ON"
}
