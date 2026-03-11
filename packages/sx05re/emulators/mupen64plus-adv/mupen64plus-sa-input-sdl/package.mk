# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert

PKG_NAME="mupen64plus-sa-input-sdl"
PKG_VERSION="5e20c6f87b73a07c92148cc4d11f9dfb3b0b0f15"
PKG_SHA256="113558329487f8fba6c6fe361a1ff5863d0e3088c26dde6f1a4eb6c599762917"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/mupen64plus/mupen64plus-input-sdl"
PKG_URL="https://github.com/mupen64plus/mupen64plus-input-sdl/archive/${PKG_VERSION}.tar.gz"
# Corrigida a dependência para o nome correto do pacote core
PKG_DEPENDS_TARGET="toolchain ${OPENGLES} libpng SDL2 SDL2_net zlib freetype nasm:host mupen64plus-sa-core"
PKG_SHORTDESC="mupen64plus-input-sdl"
PKG_LONGDESC="Mupen64Plus Standalone Input SDL (Optimized for ADV project)"
PKG_TOOLCHAIN="manual"

# Otimização para o seu S905L
export CFLAGS="${CFLAGS} -Ofast -mcpu=cortex-a53 -ftree-vectorize"

make_target() {
  export HOST_CPU=aarch64
  # Apontando para o diretório de headers do Core que já compilamos
  export APIDIR=$(get_build_dir mupen64plus-sa-core)/src/api
  export USE_GLES=1
  export SDL_CFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -D_REENTRANT"
  export SDL_LDLIBS="-lSDL2_net -lSDL2"
  export CROSS_COMPILE="${TARGET_PREFIX}"
  export V=1
  export VC=0
  
  sed -i 's/\-O[23]/-Ofast/' projects/unix/Makefile
  
  make -C projects/unix clean
  make -C projects/unix all USE_GLES=1
}

makeinstall_target() {
  # --- CAMINHOS AJUSTADOS PARA O PROJETO ADV ---
  UPREFIX=${INSTALL}/usr/local
  ULIBDIR=${UPREFIX}/lib/mupen64plus-adv
  USHAREDIR=${UPREFIX}/share/mupen64plus-adv
  
  mkdir -p ${ULIBDIR}
  mkdir -p ${USHAREDIR}

  # 1. Instala o Plugin na pasta correta onde o UI-Console vai procurar
  cp ${PKG_BUILD}/projects/unix/mupen64plus-input-sdl.so ${ULIBDIR}/
  chmod 0644 ${ULIBDIR}/mupen64plus-input-sdl.so

  # 2. RESOLVENDO O CONTROLE: Instala o arquivo de configuração no local correto
  # Verificamos primeiro no diretório do pacote (config/)
  if [ -f "${PKG_DIR}/config/InputAutoCfg.ini" ]; then
    cp ${PKG_DIR}/config/InputAutoCfg.ini ${USHAREDIR}/
  else
    # Se não estiver lá, tenta pegar o padrão que vem no código fonte
    cp ${PKG_BUILD}/data/InputAutoCfg.ini ${USHAREDIR}/
  fi
  
  chmod 644 ${USHAREDIR}/InputAutoCfg.ini
}