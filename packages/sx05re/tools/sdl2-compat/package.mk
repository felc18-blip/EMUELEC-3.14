PKG_NAME="sdl2-compat"
PKG_VERSION="main"
PKG_LICENSE="ZLIB"
PKG_SITE="https://github.com/libsdl-org/sdl2-compat"
PKG_URL="https://github.com/libsdl-org/sdl2-compat/archive/refs/heads/${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain SDL3"

PKG_LONGDESC="Compatibility layer allowing SDL2 apps to run on SDL3."

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=ON \
                       -DSDL2COMPAT_STATIC=OFF \
                       -DSDL2COMPAT_TESTS=OFF \
                       -DSDL2COMPAT_X11=OFF \
					   -DSDL_FBDEV=ON \
                       -DSDL_VIDEO_DRIVER_FBDEV=ON \
                       -DX11_FOUND=FALSE"

post_makeinstall_target() {

  mkdir -p ${INSTALL}/usr/lib/sdl3

  # mover todas as libs SDL2 do compat para pasta isolada
  for f in libSDL2-2.0.so* libSDL2.so; do
    if [ -e ${INSTALL}/usr/lib/$f ]; then
      mv ${INSTALL}/usr/lib/$f ${INSTALL}/usr/lib/sdl3/
    fi
  done

  # remover libs de teste que não são necessárias
  rm -f ${INSTALL}/usr/lib/libSDL2_test.a
  rm -f ${INSTALL}/usr/lib/libSDL2main.a

}