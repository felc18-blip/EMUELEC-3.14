# SPDX-License-Identifier: GPL-2.0
# NextOS-Elite-Edition: SDL3_net (no tagged release yet — pin main commit)

PKG_NAME="SDL3_net"
PKG_VERSION="5af3b068ea13f888be954801c0b8c17993811850"
PKG_LICENSE="ZLIB"
PKG_SITE="https://github.com/libsdl-org/SDL_net"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="SDL3_net-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain SDL3"
PKG_DEPENDS_HOST="toolchain:host"
PKG_LONGDESC="SDL3_net: network library (SDL3)"
PKG_TOOLCHAIN="cmake"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DSDLNET_TESTS=OFF \
                         -DSDLNET_SAMPLES=OFF \
                         -DBUILD_SHARED_LIBS=ON"
}

post_makeinstall_target() {
  # Aplicar fixups em ambos: ${INSTALL} (install_pkg pra imagem final)
  # e ${SYSROOT_PREFIX} (que vai pro toolchain sysroot pra outros builds).
  local _root
  for _root in "${INSTALL}" "${SYSROOT_PREFIX}"; do
    [ -d "${_root}/usr/lib/pkgconfig" ] || continue

    # Upstream cmake instala sdl3-net.pc (lowercase-hifen). scummvm e
    # outros consumers ainda procuram SDL3_net (CamelCase). Criar alias.
    if [ -f "${_root}/usr/lib/pkgconfig/sdl3-net.pc" ] && \
       [ ! -e "${_root}/usr/lib/pkgconfig/SDL3_net.pc" ]; then
      ln -s sdl3-net.pc ${_root}/usr/lib/pkgconfig/SDL3_net.pc
    fi

    # scummvm usa <SDL3/SDL_net.h>, upstream instala em SDL3_net/SDL_net.h.
    if [ -f "${_root}/usr/include/SDL3_net/SDL_net.h" ]; then
      mkdir -p ${_root}/usr/include/SDL3
      [ -e "${_root}/usr/include/SDL3/SDL_net.h" ] || \
        ln -s ../SDL3_net/SDL_net.h ${_root}/usr/include/SDL3/SDL_net.h
    fi
  done
}
