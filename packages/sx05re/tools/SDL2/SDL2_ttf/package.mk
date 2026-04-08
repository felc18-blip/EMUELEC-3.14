PKG_NAME="SDL2_ttf"
PKG_VERSION="2.20.2"
PKG_LICENSE="ZLIB"
PKG_SITE="https://github.com/libsdl-org/SDL_ttf"
PKG_URL="${PKG_SITE}/archive/refs/tags/release-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain SDL2 freetype"

PKG_TOOLCHAIN="cmake"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DSDL2TTF_VENDORED=OFF"
}
