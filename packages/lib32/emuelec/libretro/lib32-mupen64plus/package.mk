# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-mupen64plus"
PKG_VERSION="$(get_pkg_version mupen64plus)"
PKG_NEED_UNPACK="$(get_pkg_directory mupen64plus)"
PKG_ARCH="aarch64"
PKG_REV="1"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain nasm:host lib32-${OPENGLES} lib32-zlib"
PKG_PATCH_DIRS+=" $(get_pkg_directory mupen64plus)/patches"
PKG_TOOLCHAIN="manual"
PKG_BUILD_FLAGS="lib32 -lto"

# Plataforma para Amlogic 32-bit
PKG_MAKE_OPTS_TARGET="platform=odroid BOARD=c2"

unpack() {
  ${SCRIPTS}/get mupen64plus
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/mupen64plus/mupen64plus-${PKG_VERSION}.tar.gz -C ${PKG_BUILD}
}

pre_configure_target() {
  find ${PKG_BUILD} -type f \( -name "*.c" -o -name "*.h" -o -name "*.def" -o -name "*.cpp" \) -exec sed -i 's/\<fsqrt\>/mupen_fsqrt/g' {} +

  # No 32-bit o arquivo geralmente é new_dynarec.c (sem o _64)
  if [ -f "${PKG_BUILD}/mupen64plus-core/src/r4300/new_dynarec/new_dynarec.c" ]; then
    sed -i 's/#define assem_debug nullf/#define assem_debug(...)/g' ${PKG_BUILD}/mupen64plus-core/src/r4300/new_dynarec/new_dynarec.c
    sed -i 's/#define inv_debug nullf/#define inv_debug(...)/g' ${PKG_BUILD}/mupen64plus-core/src/r4300/new_dynarec/new_dynarec.c
  fi

  # 3. 🔥 Vacina do CRC (Tipo incompatível no zip.c)
  if [ -f "${PKG_BUILD}/mupen64plus-core/src/main/zip/zip.c" ]; then
    sed -i 's/zi->ci.pcrc_32_tab = get_crc_table();/zi->ci.pcrc_32_tab = (const long unsigned int *)get_crc_table();/g' ${PKG_BUILD}/mupen64plus-core/src/main/zip/zip.c
  fi

  # Flags de compatibilidade e otimização
  export CFLAGS="${CFLAGS} -DLINUX -DEGL_API_FB -fcommon -Wno-implicit-function-declaration -Wno-incompatible-pointer-types"
  export CPPFLAGS="${CPPFLAGS} -DLINUX -DEGL_API_FB"
  export LDFLAGS="${LDFLAGS} -lz"

  # Ajustes de Makefile e remoção de CPU conflitante
  sed -i "s|BOARD :=.*|BOARD = N2|g" Makefile
  sed -i "s|odroid64|emuelec64|g" Makefile
  sed -i 's/-mcpu=cortex-a9//g' Makefile
  sed -i 's/\-O[23]/-Ofast/' Makefile
}

make_target() {
  make ${PKG_MAKE_OPTS_TARGET} -j$(nproc)
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_libretro.so ${INSTALL}/usr/lib/libretro/mupen64plus_32b_libretro.so
}
