# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="vector06sdl"
PKG_VERSION="5cbd54023df430446e283cb874cac36d71359d73"
PKG_SHA256="553b018d9a45dc7fb7558583ddf7db12481c29b8ed00a56b22ef41df165ff65a"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/svofski/vector06sdl"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain freetype slang alsa boost SDL2 SDL2_image"
PKG_LONGDESC="Opensource Vector-06C emulator in C++"

pre_configure_target() {
# NextOS:
# - CMAKE_POLICY_VERSION_MINIMUM=3.5 — CMake 4 removeu compat <3.5
# - SYSTEM_PROCESSOR=aarch64 — patch tem branch elseif p/ aarch64 (BFDNAME correto)
# - OBJCOPY do cross-toolchain — host objcopy gera ELF x86_64 que linker recusa
PKG_CMAKE_OPTS_TARGET="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_SYSTEM_PROCESSOR=aarch64 -DUSE_XXD=true -DSDL2_LIBRARY=${SYSROOT_PREFIX}/usr/lib/libSDL2.so -DSDL2_IMAGE_LIBRARY=${SYSROOT_PREFIX}/usr/lib/libSDL2_image.so"
# NextOS: BIN2OBJ via xxd gera arquivos .c que sao compilados por `cc` (host).
# Trocamos `cc` por cross-gcc senao linker reclama de ELF x86_64 vs aarch64.
sed -i "s|COMMAND cc -c|COMMAND ${CC} -c|g" ${PKG_BUILD}/CMakeLists.txt
# NextOS: GCC 15.2 / std=gnu++17 — std::clamp/find_if/remove_if precisam
# <algorithm> mas varios .cpp nao incluem (eram transitivos no <vector> antigo).
for f in memory.cpp debug.cpp fsimage.cpp utils_string.cpp; do
  [ -f "${PKG_BUILD}/src/$f" ] && \
    grep -q "^#include <algorithm>" ${PKG_BUILD}/src/$f || \
    sed -i '1a #include <algorithm>' ${PKG_BUILD}/src/$f 2>/dev/null
done
# NextOS: Boost 1.66+ renomeou boost::asio::io_service -> io_context.
# Boost 1.90 removeu io_service. server.cpp usa API antiga.
sed -i 's|boost::asio::io_service|boost::asio::io_context|g' ${PKG_BUILD}/src/server.cpp
sed -i 's|io_service&|io_context\&|g' ${PKG_BUILD}/src/server.cpp
}

makeinstall_target() {
  # NextOS: CMakeLists upstream nao tem regra install — copiamos manualmente.
  mkdir -p ${INSTALL}/usr/bin
  cp -f ${PKG_BUILD}/.${TARGET_NAME}/v06x ${INSTALL}/usr/bin/v06x

  # NextOS: launcher c/ --opengl=disable + gptokeyb wrapper
  cp -f ${PKG_DIR}/scripts/vector06.start ${INSTALL}/usr/bin/vector06.start
  chmod +x ${INSTALL}/usr/bin/vector06.start

  # NextOS: gptokeyb config (Select+Start = kill v06x)
  mkdir -p ${INSTALL}/usr/config/emuelec/configs/gptokeyb
  cp -f ${PKG_DIR}/config/gptokeyb/vector06.gptk \
        ${INSTALL}/usr/config/emuelec/configs/gptokeyb/vector06.gptk
}
