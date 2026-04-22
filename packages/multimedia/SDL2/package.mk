# SPDX-License-Identifier: GPL-2.0-or-later
#
# "SDL2" package - agora usa sdl2-compat ao inves de SDL2 classic.
# sdl2-compat e uma lib wrapper binary-compatible com SDL2 que delega
# chamadas para o SDL3 por baixo. Como temos SDL3 com driver Mali FBDEV,
# todos os apps SDL2 passam a usar o SDL3 Mali transparentemente.
#
# Nome do package continua "SDL2" para nao quebrar as dependencias dos
# 30+ packages que listam SDL2 em PKG_DEPENDS_TARGET.

PKG_NAME="SDL2"
PKG_VERSION="2.32.66"
PKG_LICENSE="Zlib"
PKG_SITE="https://github.com/libsdl-org/sdl2-compat"
PKG_URL="https://github.com/libsdl-org/sdl2-compat/releases/download/release-${PKG_VERSION}/sdl2-compat-${PKG_VERSION}.tar.gz"
PKG_ARCH="any"

# Dependências transitivas vêm via SDL3 (alsa-lib, pulseaudio, mali, etc.)
PKG_DEPENDS_HOST="toolchain:host SDL3:host SDL3"
PKG_DEPENDS_TARGET="toolchain SDL3"

PKG_LONGDESC="sdl2-compat: SDL2 API implemented on top of SDL3 (binary compatible wrapper)"
PKG_TOOLCHAIN="cmake"

# Opcoes comuns que desabilitam TUDO exceto a lib principal
_SDL2COMPAT_COMMON="-DSDL2COMPAT_TESTS=OFF \
                    -DSDL2COMPAT_INSTALL=ON \
                    -DSDL2COMPAT_INSTALL_CPACK=OFF \
                    -DSDL2COMPAT_STATIC=OFF \
                    -DBUILD_SHARED_LIBS=ON \
                    -DSDL2COMPAT_X11=OFF \
                    -DSDL2COMPAT_WAYLAND=OFF \
                    -DSDL2COMPAT_WERROR=OFF \
                    -DCMAKE_BUILD_TYPE=Release"

PKG_CMAKE_OPTS_HOST="${_SDL2COMPAT_COMMON}"
PKG_CMAKE_OPTS_TARGET="${_SDL2COMPAT_COMMON}"


post_makeinstall_target() {
  # Fix paths do sdl2-config pra apontar pro sysroot no build time
  if [ -f "${SYSROOT_PREFIX}/usr/bin/sdl2-config" ]; then
    sed -e "s:\(['=LI]\)/usr:\\1${SYSROOT_PREFIX}/usr:g" -i ${SYSROOT_PREFIX}/usr/bin/sdl2-config
  fi

  # Instala sdl2.pc no sysroot do target.
  # O sdl2-compat gera "sdl2-compat.pc" (nome errado) e o build
  # system nao copia pro sysroot. Criamos um sdl2.pc correto aqui.
  mkdir -p "${SYSROOT_PREFIX}/usr/lib/pkgconfig"
  cat > "${SYSROOT_PREFIX}/usr/lib/pkgconfig/sdl2.pc" <<EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: sdl2
Description: Simple DirectMedia Layer (sdl2-compat on top of SDL3)
Version: 2.30.0
Libs: -L\${libdir} -lSDL2
Libs.private: -lm -ldl -lpthread
Cflags: -I\${includedir} -I\${includedir}/SDL2 -D_GNU_SOURCE=1 -D_REENTRANT
EOF

  # Copia tambem pro INSTALL pra runtime
  mkdir -p "${INSTALL}/usr/lib/pkgconfig"
  cp "${SYSROOT_PREFIX}/usr/lib/pkgconfig/sdl2.pc" "${INSTALL}/usr/lib/pkgconfig/sdl2.pc"

  safe_remove ${INSTALL}/usr/bin
}
