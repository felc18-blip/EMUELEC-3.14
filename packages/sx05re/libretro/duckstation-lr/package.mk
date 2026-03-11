# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="duckstation-lr"
PKG_VERSION="24c373245ebdab946f11627520edea76e1f23b8e"
PKG_ARCH="any"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/stenzek/duckstation"
PKG_URL="${PKG_SITE}.git"
# Dependências ajustadas para o EmuELEC
PKG_DEPENDS_TARGET="toolchain SDL2 zlib curl libevdev zstd libwebp"
PKG_SECTION="libretro"
PKG_SHORTDESC="DuckStation - PS1 Emulator (Libretro)"
PKG_TOOLCHAIN="cmake"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET+=" -DBUILD_SDL_FRONTEND=OFF \
                           -DBUILD_QT_FRONTEND=OFF \
                           -DBUILD_LIBRETRO_CORE=ON \
                           -DENABLE_DISCORD_PRESENCE=OFF \
                           -DUSE_X11=OFF \
                           -DENABLE_WAYLAND=OFF \
                           -DUSE_GLES2=ON \
                           -DUSE_SYSTEM_LIBS=OFF \
                           -DUSE_BUNDLED_ZSTD=ON"

  if [ "${TARGET_ARCH}" = "aarch64" ]; then
    CFLAGS+=" -mcpu=cortex-a53 -Ofast"
    CXXFLAGS+=" -mcpu=cortex-a53 -Ofast"
  fi
}

make_target() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive

  # --- CORREÇÃO DO ERRO 'INDEX IS NOT A CONSTANT EXPRESSION' ---
  # Substitui o offsetof problemático por um cálculo de endereço que o GCC antigo aceita
  sed -i 's/offsetof(State, gte_regs.r32\[index\])/offsetof(State, gte_regs.r32) + (sizeof(u32) * index)/g' src/core/cpu_recompiler_code_generator.cpp

  # Curativo para o arquivo 252 (que você já tinha feito)
  sed -i '1i #include <algorithm>\n#include <cstdio>\n#include <stdint.h>' src/duckstation-libretro/libretro_host_interface.cpp

  # Entra na pasta de build e continua
  cd .aarch64-libreelec-linux-gnu
  ninja -j2
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  # Procura o binário em qualquer subpasta (o CMake às vezes muda o local)
  find ${PKG_BUILD} -name "duckstation_libretro.so" -exec cp {} ${INSTALL}/usr/lib/libretro/ \;
  # 'Strip' remove lixo e deixa o arquivo leve para a RAM da Box
  ${STRIP} ${INSTALL}/usr/lib/libretro/duckstation_libretro.so
}