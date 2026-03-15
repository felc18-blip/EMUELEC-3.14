PKG_NAME="ti99sim"
PKG_VERSION="0.16.0"
PKG_SHA256="14bd72f372fe1a253c3a25bca579d29b5c3e47aff2f22622188dc4023576b159"
PKG_LICENSE="GPL-3.0"
PKG_SITE="https://www.mrousseau.org/programs/ti99sim/"
PKG_URL="https://www.mrousseau.org/programs/ti99sim/archives/ti99sim-${PKG_VERSION}.src.tar.xz"

PKG_DEPENDS_TARGET="toolchain SDL2 openssl"
PKG_LONGDESC="TI-99/4A Emulator"
PKG_TOOLCHAIN="make"

pre_configure_target() {
  # Limpeza preventiva de qualquer flag de arquitetura que cause conflito
  find . -name "rules.mak" -o -name "Makefile*" -exec sed -i 's/-march=aarch64//g' {} +
  find . -name "rules.mak" -o -name "Makefile*" -exec sed -i 's/-march=$(ARCH)//g' {} +
  
  # Correção de include (essencial para o GCC moderno)
  f="$PKG_BUILD/src/core/device-support.cpp"
  [ -f "$f" ] && sed -i '/#include "cf7+.hpp"/a #include <cstring>' "$f"
}

pre_make_target() {
  # Compila o core com flags limpas
  make -C "$PKG_BUILD/src/core" CC="$CC" CXX="$CXX" AR="$AR" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS"
}

make_target() {
  # Mantemos a compilação que remove o erro de caminho
  make -C "$PKG_BUILD/src/sdl" \
    CC="$CC" \
    CXX="$CXX" \
    SDL2=1 \
    SDL2_CFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2" \
    SDL2_LIBS="-L${SYSROOT_PREFIX}/usr/lib -lSDL2" \
    CFLAGS="$CFLAGS -I../core -I${SYSROOT_PREFIX}/usr/include/SDL2" \
    CXXFLAGS="$CXXFLAGS -I../core -I${SYSROOT_PREFIX}/usr/include/SDL2" \
    LDFLAGS="$LDFLAGS"
}

makeinstall_target() {
  # 1. Criamos a pasta de destino no sistema de arquivos do EmuELEC
  mkdir -p ${INSTALL}/usr/bin

  # 2. Copiamos o binário manualmente (evitando o comando 'make install' quebrado)
  # Procuramos o binário na pasta bin ou src/sdl
  if [ -f "${PKG_BUILD}/bin/ti99sim-sdl" ]; then
    cp "${PKG_BUILD}/bin/ti99sim-sdl" "${INSTALL}/usr/bin/ti99sim-sdl"
  elif [ -f "${PKG_BUILD}/src/sdl/ti99sim-sdl" ]; then
    cp "${PKG_BUILD}/src/sdl/ti99sim-sdl" "${INSTALL}/usr/bin/ti99sim-sdl"
  fi

  chmod +x ${INSTALL}/usr/bin/ti99sim-sdl

  # 3. Copiamos o script de inicialização se ele existir
  if [ -f "${PKG_DIR}/scripts/ti99sdlstart.sh" ]; then
    cp "${PKG_DIR}/scripts/ti99sdlstart.sh" "${INSTALL}/usr/bin/ti99sdlstart.sh"
    chmod +x ${INSTALL}/usr/bin/ti99sdlstart.sh
  fi
}