# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="flycast"
PKG_VERSION="c57b2e1aa775c21f6ddcd090607f4b3ba1a1baa1"
PKG_SITE="https://github.com/flyinghead/flycast"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain zlib libzip"
PKG_LONGDESC="Flycast is a multi-platform Sega Dreamcast, Naomi and Atomiswave emulator"
PKG_TOOLCHAIN="cmake"
PKG_PATCH_DIRS+=" ${DEVICE}"
PKG_BUILD_FLAGS="-parallel"

# Lógica unificada para GLES/OpenGL
if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  # Para dispositivos ARM/Mali (Amlogic, Rockchip, etc)
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_OPENGL=ON -DUSE_GLES=ON"
elif [ "${OPENGL_SUPPORT}" = "yes" ]; then
  # Para PC/x86 com OpenGL Desktop
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_OPENGL=ON -DUSE_GLES=OFF"
else
  # Sem suporte a GPU (Software Rendering - muito lento!)
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_OPENGL=OFF -DUSE_GLES=OFF"
fi

# Vulkan (Geralmente OFF em Amlogic-old, mas mantemos a lógica)
if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${VULKAN}"
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_VULKAN=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_VULKAN=OFF"
fi

pre_configure_target() {
  sed -i 's/"reicast"/"flycast"/g' ${PKG_BUILD}/shell/libretro/libretro_core_option_defines.h
  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/CMakeLists.txt
  PKG_CMAKE_OPTS_TARGET="${PKG_CMAKE_OPTS_TARGET} \
			 -Wno-dev -DLIBRETRO=ON \
                         -DWITH_SYSTEM_ZLIB=ON \
                         -DUSE_OPENMP=ON"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro

  # Se a arquitetura for ARM (32-bit), instala com o sufixo 32b
  if [ "${ARCH}" == "arm" ]; then
    cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/flycast_32b_libretro.so
  else
    # Se for AARCH64 (64-bit), instala o nome padrão
    cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/flycast_libretro.so
  fi

  # Instala as configurações do pacote
  mkdir -p ${INSTALL}/usr/config/retroarch
  if [ -d "${PKG_DIR}/config" ]; then
    cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/retroarch/
  fi
}
