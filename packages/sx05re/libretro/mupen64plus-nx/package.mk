# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert

PKG_NAME="mupen64plus-nx"
PKG_VERSION="222acbd3f98391458a047874d0372fe78e14fe94"
PKG_SHA256="9e55fa83f2313f9b80a369d77457ec216e5774ef2d486083ad8661aa94a4dbd1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro-nx"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host ${OPENGLES}"
PKG_SECTION="libretro"
PKG_SHORTDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_LONGDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-lto"

pre_configure_target() {
  cd ${PKG_BUILD}

  sed -e "s|^GIT_VERSION ?.*$|GIT_VERSION := \" ${PKG_VERSION:0:7}\"|" -i Makefile

  # remover BOM
  find . -type f \( -name "*.h" -o -name "*.cpp" \) -exec sed -i '1s/^\xef\xbb\xbf//' {} +

  # FIX ptrdiff_t (CRÍTICO)
  sed -i 's/#define ptrdiff_t khronos_ssize_t//g' libretro-common/include/glsm/glsm.h

  # includes corretos (C vs C++)
  find GLideN64 -type f \( -name "*.cpp" -o -name "*.hpp" \) \
    -exec sed -i '1i #include <cstdint>\n#include <ctime>\n#include <atomic>' {} +

  find GLideN64 -type f \( -name "*.c" -o -name "*.h" \) \
    -exec sed -i '1i #include <stdint.h>\n#include <time.h>' {} +

  # fsqrt fix
  find . -type f \( -name "*.c" -o -name "*.h" -o -name "*.def" -o -name "*.cpp" \) \
    -exec sed -i 's/\<fsqrt\>/mupen_fsqrt/g' {} +

  # nullf fix
  if [ -f "mupen64plus-core/src/r4300/new_dynarec/new_dynarec_64.c" ]; then
    sed -i 's/#define assem_debug nullf/#define assem_debug(...)/g' \
      mupen64plus-core/src/r4300/new_dynarec/new_dynarec_64.c
    sed -i 's/#define inv_debug nullf/#define inv_debug(...)/g' \
      mupen64plus-core/src/r4300/new_dynarec/new_dynarec_64.c
  fi

  # flags gcc15
  export CFLAGS="$CFLAGS -fcommon -fpermissive -Wno-implicit-function-declaration -Wno-error"
  export CXXFLAGS="$CXXFLAGS -fcommon -fpermissive -Wno-template-body -Wno-error -DGL_GLEXT_PROTOTYPES"

  if [ "${DEVICE}" = "Amlogic-old" ]; then
    PKG_MAKE_OPTS_TARGET+=" platform=emuelec BOARD=OLD HAVE_PARALLEL_RDP=0 HAVE_PARALLEL_RSP=0 LLE=1"
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_next_libretro.so ${INSTALL}/usr/lib/libretro/
}
