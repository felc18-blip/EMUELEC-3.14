# SPDX-License-Identifier: GPL-2.0-or-later
#
# lib32-SDL2: agora é sdl2-compat 32-bit rodando sobre lib32-SDL3.
# Preserva o nome "lib32-SDL2" e SONAME "libSDL2-2.0.so.0"
# para que os packages 32-bit (retroarch, mupen64plus-sa, etc) continuem funcionando.

PKG_NAME="lib32-SDL2"
PKG_VERSION="$(get_pkg_version SDL2)"
PKG_NEED_UNPACK="$(get_pkg_directory SDL2)"
PKG_ARCH="aarch64"
PKG_LICENSE="Zlib"
PKG_SITE="https://github.com/libsdl-org/sdl2-compat"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-SDL3"
PKG_LONGDESC="sdl2-compat lib32: SDL2 API on top of SDL3 (binary compatible)"
PKG_BUILD_FLAGS="lib32"

PKG_CMAKE_OPTS_TARGET="-DSDL2COMPAT_TESTS=OFF \
                       -DSDL2COMPAT_INSTALL=ON \
                       -DSDL2COMPAT_INSTALL_CPACK=OFF \
                       -DSDL2COMPAT_STATIC=OFF \
                       -DBUILD_SHARED_LIBS=ON \
                       -DSDL2COMPAT_X11=OFF \
                       -DSDL2COMPAT_WAYLAND=OFF"

unpack() {
  ${SCRIPTS}/get SDL2
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/SDL2/SDL2-${PKG_VERSION}.tar.gz -C ${PKG_BUILD}
}


post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/bin
  safe_remove ${INSTALL}/usr/include
  safe_remove ${INSTALL}/usr/share

  # Fix: renomeia sdl2-compat.pc para sdl2.pc com Name correto.
  # O pkg-config 0.29.2 (classic) nao resolve Provides: sdl2, so acha pelo filename.
  # Aplica no INSTALL (pra runtime) e no SYSROOT_PREFIX (pra build-time de outros packages).
  for PCDIR in "${INSTALL}/usr/lib/pkgconfig" "${SYSROOT_PREFIX}/usr/lib/pkgconfig"; do
    if [ -f "${PCDIR}/sdl2-compat.pc" ]; then
      sed -e 's/^Name:.*/Name: sdl2/' \
          -e '/^Provides:/d' \
          -e 's/^Description:.*/Description: Simple DirectMedia Layer (sdl2-compat on top of SDL3)/' \
          "${PCDIR}/sdl2-compat.pc" > "${PCDIR}/sdl2.pc"
      rm -f "${PCDIR}/sdl2-compat.pc"
    fi
  done

  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}
