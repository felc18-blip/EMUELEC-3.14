PKG_NAME="mpv"
PKG_VERSION="v0.36.0"
PKG_LICENSE="GPLv2+"
PKG_SITE="https://github.com/mpv-player/mpv"
PKG_URL="https://github.com/mpv-player/mpv/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ffmpeg SDL2 luajit libass libplacebo"
PKG_TOOLCHAIN="manual"

pre_configure_target() {
  cp ${PKG_DIR}/waf ${PKG_BUILD}/waf
  chmod +x ${PKG_BUILD}/waf
}

configure_target() {
  cd ${PKG_BUILD}

  python3 ./waf configure \
    --enable-cplayer \
    --enable-libmpv-shared \
    --enable-sdl2 \
    --enable-sdl2-gamepad \
    --disable-pulse \
    --enable-egl \
    --disable-libbluray \
    --disable-drm \
    --disable-gl
}

make_target() {
  python3 ./waf build
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp build/mpv ${INSTALL}/usr/bin
}