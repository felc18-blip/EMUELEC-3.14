# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-parallel-n64"
PKG_VERSION="$(get_pkg_version parallel-n64)"
PKG_NEED_UNPACK="$(get_pkg_directory parallel-n64)"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/parallel-n64"
PKG_URL=""

PKG_DEPENDS_TARGET="lib32-toolchain lib32-${OPENGLES}"
P64_DIRECTORY="$(get_pkg_directory parallel-n64)"
PKG_PATCH_DIRS+=" ${P64_DIRECTORY}/patches ${P64_DIRECTORY}/patches/arm ${P64_DIRECTORY}/patches/emuelec-arm32"
PKG_LONGDESC="Optimized/rewritten Nintendo 64 emulator made specifically for Libretro. Originally based on Mupen64 Plus."
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="lib32 -lto"

case ${DEVICE} in
  OdroidGoAdvance|GameForce)
    PKG_MAKE_OPTS_TARGET="platform=Odroidgoa"
  ;;
  RK356x|OdroidM1)
    PKG_MAKE_OPTS_TARGET="platform=Odroidgoa-RK356x"
  ;;
  *)
    PKG_MAKE_OPTS_TARGET="platform=${DEVICE}"
  ;;
esac

# CORREÇÃO DINÂMICA: Neutraliza bibliotecas vazias em qualquer plataforma selecionada
PKG_MAKE_OPTS_TARGET+=" GL_LIB= EGL_LIB="

unpack() {
  ${SCRIPTS}/get parallel-n64
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/parallel-n64/parallel-n64-${PKG_VERSION}.tar.gz -C ${PKG_BUILD}

  # VACINA FSQRT: Evita conflito com GCC 15/math.h do sistema
  find ${PKG_BUILD} -type f \( -name "*.h" -o -name "*.c" -o -name "*.cpp" \) -print0 | xargs -0 sed -i 's/\bfsqrt\b/fsqrt_n64/g'
}

pre_configure_target() {
  # Flags de compatibilidade C99 e correção de linkagem para Libretro
  export CFLAGS="${CFLAGS} -std=gnu99 -fcommon -Wno-implicit-function-declaration -Wno-error"
  export CXXFLAGS="${CXXFLAGS} -fcommon -Wno-error"
  export LDFLAGS="${LDFLAGS} -Wl,--allow-shlib-undefined"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp parallel_n64_libretro.so ${INSTALL}/usr/lib/libretro/parallel_n64_32b_libretro.so
}
