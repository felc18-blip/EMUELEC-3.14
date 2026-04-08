# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS Elite Edition - Mupen64Plus Libretro (Fixed Platform)

PKG_NAME="mupen64plus-lr"
PKG_VERSION="ab8134ac90a567581df6de4fc427dd67bfad1b17"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host"
PKG_LONGDESC="mupen64plus + RSP-HLE + GLideN64 + libretro optimized for ARM64"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-lto"
PKG_PATCH_DIRS+=" ${DEVICE}"

if [ "${OPENGL}" = "yes" ] && [ ! "${PREFER_GLES}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu"
  PKG_MAKE_OPTS_TARGET+=" GLES=0 GL_LIB=\"-lGL\""
elif [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  # Forçamos GLES=1 e garantimos que o Makefile saiba que é para usar GLES2
  PKG_MAKE_OPTS_TARGET+=" GLES=1 GL_LIB=\"-lGLESv2\" HAVE_GLES2=1"
fi

pre_configure_target() {
  export CFLAGS="${CFLAGS} -fcommon -Wno-error=incompatible-pointer-types -std=gnu17"

  case ${ARCH} in
    aarch64)
      # TROCA CRÍTICA: 'unix' faz o Makefile sair do modo Windows.
      # WITH_DYNAREC=arm64 ativa o motor de alta performance.
      PKG_MAKE_OPTS_TARGET+=" platform=unix OS_LINUX=1 WITH_DYNAREC=arm64"
    ;;
  esac

  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/Makefile
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_libretro.so ${INSTALL}/usr/lib/libretro/mupen64plus-lr_libretro.so
}
