# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="mupen64plus-lr"
PKG_VERSION="ab8134ac90a567581df6de4fc427dd67bfad1b17"
PKG_REV="1"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host ${OPENGLES}"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_LONGDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-lto"
PKG_PATCH_DIRS+=" ${DEVICE}"

pre_configure_target() {
  cd ${PKG_BUILD}

  # 🔥 FOCO DE HOJE: Resolver o conflito do 'fsqrt'
  # Este comando percorre o código e muda o nome da função interna para mupen_fsqrt
  find . -type f \( -name "*.c" -o -name "*.h" -o -name "*.def" -o -name "*.cpp" \) -exec sed -i 's/\<fsqrt\>/mupen_fsqrt/g' {} +

  # Mantendo a correção do nullf que já passamos (variadic macro)
  if [ -f "mupen64plus-core/src/r4300/new_dynarec/new_dynarec_64.c" ]; then
    sed -i 's/#define assem_debug nullf/#define assem_debug(...)/g' mupen64plus-core/src/r4300/new_dynarec/new_dynarec_64.c
    sed -i 's/#define inv_debug nullf/#define inv_debug(...)/g' mupen64plus-core/src/r4300/new_dynarec/new_dynarec_64.c
  fi

  # Configurações básicas de plataforma
  PKG_MAKE_OPTS_TARGET+=" platform=unix HAVE_OPENGL=0 HAVE_OPENGLES=1 FORCE_GLES=1 WITH_DYNAREC=aarch64"

  # Forçar flags de compatibilidade do GCC 15
  CFLAGS="${CFLAGS} -fcommon -Wno-implicit-function-declaration -Wno-incompatible-pointer-types"
  CXXFLAGS="${CXXFLAGS} -fcommon"

  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/Makefile
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_libretro.so ${INSTALL}/usr/lib/libretro/mupen64plus-lr_libretro.so
}
