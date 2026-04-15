# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-mupen64plus"
PKG_VERSION="$(get_pkg_version mupen64plus)"
PKG_NEED_UNPACK="$(get_pkg_directory mupen64plus)"
PKG_ARCH="aarch64"
PKG_REV="1"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain nasm:host lib32-${OPENGLES}"
PKG_PATCH_DIRS+=" $(get_pkg_directory mupen64plus)/patches"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="mupen64plus NX libretro"
PKG_LONGDESC="mupen64plus NX libretro"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="lib32 -lto"

if [ "${PROJECT}" = "Amlogic-ce" ]; then
  # CORREÇÃO: Esvaziamos as bibliotecas vazias e mantemos o Dynarec em 0 por estabilidade
  PKG_MAKE_OPTS_TARGET="platform=unix GLES=1 FORCE_GLES=1 HAVE_NEON=1 WITH_DYNAREC=0 GL_LIB= EGL_LIB="
elif [[ "${DEVICE}" =~ ^(OdroidGoAdvance|GameForce|RK356x|OdroidM1)$ ]]; then
  PKG_MAKE_OPTS_TARGET="platform=unix GLES=1 FORCE_GLES=1 HAVE_NEON=1 WITH_DYNAREC=arm"
fi

unpack() {
  ${SCRIPTS}/get mupen64plus
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/mupen64plus/mupen64plus-${PKG_VERSION}.tar.gz -C ${PKG_BUILD}

  # 🔥 VACINA BLINDADA: Renomeia fsqrt para evitar conflito com math.h do sistema
  find ${PKG_BUILD} -type f \( -name "*.h" -o -name "*.c" -o -name "*.cpp" \) -print0 | xargs -0 sed -i 's/\bfsqrt\b/fsqrt_m64p/g'
}

pre_configure_target() {
  # CORREÇÃO DE LINKAGEM: Removemos a trava de símbolos indefinidos do Makefile
  # Isso permite que a linkagem passe mesmo com as libs de vídeo vazias no sysroot
  sed -i "s/-Wl,--no-undefined//g" Makefile

  export LDFLAGS="${LDFLAGS} -Wl,--allow-shlib-undefined"
  export CFLAGS="${CFLAGS} -DLINUX -DEGL_API_FB -fcommon -Wno-error -Wno-incompatible-pointer-types"
  export CXXFLAGS="${CXXFLAGS} -DLINUX -DEGL_API_FB -fcommon -Wno-error"
  export CPPFLAGS="${CPPFLAGS} -DLINUX -DEGL_API_FB"

  sed -i "s|BOARD :=.*|BOARD = N2|g" Makefile
  sed -i "s|odroid64|emuelec64|g" Makefile
  sed -i 's/-mcpu=cortex-a9//g' Makefile
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_libretro.so ${INSTALL}/usr/lib/libretro/mupen64plus_32b_libretro.so
}
