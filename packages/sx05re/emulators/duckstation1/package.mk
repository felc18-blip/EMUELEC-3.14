# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert

PKG_NAME="duckstation1"
PKG_VERSION="fd3507c16d098fb32806c281caaefb205946da8a"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/stenzek/duckstation"
PKG_URL="${PKG_SITE}.git"
# Adicionado mali-libs para garantir que as bibliotecas de vídeo estejam no ambiente de build
PKG_DEPENDS_TARGET="toolchain SDL2 zlib curl libevdev zstd libwebp libmali"
PKG_SECTION="emulators"
PKG_SHORTDESC="Fast Standalone PS1 emulator (NoGUI)"
PKG_TOOLCHAIN="cmake"

if [ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
    EXTRA_OPTS+=" -DUSE_DRMKMS=ON -DUSE_FBDEV=OFF -DUSE_MALI=OFF"
else
    # Configuração ideal para S905L (Amlogic-old)
    EXTRA_OPTS+=" -DUSE_DRMKMS=OFF -DUSE_FBDEV=ON -DUSE_MALI=ON"
fi

pre_configure_target() {
    # ADICIONADO: Flags para forçar GLES2 e vincular as bibliotecas da Mali corretamente
    PKG_CMAKE_OPTS_TARGET+=" -DANDROID=OFF \
                             -DENABLE_DISCORD_PRESENCE=OFF \
                             -DUSE_X11=OFF \
                             -DBUILD_LIBRETRO_CORE=OFF \
                             -DBUILD_QT_FRONTEND=OFF \
                             -DBUILD_NOGUI_FRONTEND=ON \
                             -DUSE_SDL2=ON \
                             -DENABLE_CHEEVOS=ON \
                             -DHAVE_EGL=ON \
                             -DUSE_GLES2=ON \
                             -DGLAD_GLES2=ON \
                             -DENABLE_VULKAN=OFF \
                             -DUSE_SYSTEM_LIBS=OFF \
                             -DUSE_BUNDLED_ZSTD=ON \
                             -DUSE_BUNDLED_FFMPEG=ON \
                             -DOPENGLES_LIBRARY=${SYSROOT_PREFIX}/usr/lib/libGLESv2.so \
                             -DEGL_LIBRARY=${SYSROOT_PREFIX}/usr/lib/libEGL.so \
                             ${EXTRA_OPTS}"

    # Otimizações de CPU para o seu dispositivo
    CFLAGS+=" -mcpu=cortex-a53 -Ofast"
    CXXFLAGS+=" -mcpu=cortex-a53 -Ofast"

    if [ "${DEVICE}" == "Amlogic-old" ]; then
        cp -rf $(get_build_dir libevdev)/include/linux/linux/input-event-codes.h ${SYSROOT_PREFIX}/usr/include/linux/
    fi
}

make_target() {
  cd ${PKG_BUILD}
  
  # Tenta atualizar submódulos
  git submodule update --init --recursive || echo "Submodules failed, forcing cleanup..."
  rm -rf dep/msvc/qt

  # --- CORREÇÕES DE CÓDIGO ---
  sed -i 's/offsetof(State, gte_regs.r32\[index\])/offsetof(State, gte_regs.r32) + (sizeof(u32) * index)/g' src/core/cpu_recompiler_code_generator.cpp
  sed -i '1i #include <algorithm>\n#include <cstdio>\n#include <stdint.h>' src/frontend-common/game_settings.cpp

  # Entra na pasta e compila
  cd .aarch64-libreelec-linux-gnu
  ninja -j2
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/config/emuelec/configs/duckstation/database

  # 1. Copia o binário
  cp -v ${PKG_BUILD}/.aarch64-libreelec-linux-gnu/bin/duckstation-nogui ${INSTALL}/usr/bin/
  
  if [ ! -f "${INSTALL}/usr/bin/duckstation-nogui" ]; then
    cp -v ${PKG_BUILD}/bin/duckstation-nogui ${INSTALL}/usr/bin/
  fi

  ${STRIP} ${INSTALL}/usr/bin/duckstation-nogui

  # 2. Copia os scripts (Certifique-se que seu duckstation.sh corrigido está na pasta 'scripts')
  if [ -d "${PKG_DIR}/scripts" ]; then
    cp -rf ${PKG_DIR}/scripts/*.sh ${INSTALL}/usr/bin/
    chmod +x ${INSTALL}/usr/bin/*.sh
  fi

  # 3. Bancos de dados
  if [ -d "${PKG_BUILD}/data/database" ]; then
    cp -rf ${PKG_BUILD}/data/database/* ${INSTALL}/usr/config/emuelec/configs/duckstation/database/
  fi
}