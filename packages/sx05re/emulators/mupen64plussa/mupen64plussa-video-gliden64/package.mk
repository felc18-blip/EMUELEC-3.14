# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 Nicholas Ricciuti (rishooty@gmail.com)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
# Copyright (C) 2026 NextOS Elite Edition

# Adaptado do backup mupen64plus-sa-video-gliden64 pra estrutura mupen64plussa.
# Build apenas a versao "base" (Amlogic-old/Mali-450 nao precisa de
# simplecore variant — esse e' p/ devices Snapdragon/RK3588 high-end).
# User reporta que esse plugin "nunca abriu" — investigacao em runtime.

PKG_NAME="mupen64plussa-video-gliden64"
PKG_VERSION="c8ef81c7d9aede9f67f6ed3d3426c90541f9f13e"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/gonetz/GLideN64"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="master"
GET_HANDLER_SUPPORT="git"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES} boost libpng SDL2 SDL2_net zlib freetype nasm:host mupen64plussa-core"
PKG_LONGDESC="Mupen64Plus Standalone GLideN64 Video Driver (NextOS port)"
PKG_TOOLCHAIN="manual"

export USE_GLES=1

make_target() {
  export HOST_CPU=${TARGET_ARCH}
  export NEW_DYNAREC=1
  export VFP_HARD=1
  export V=1
  export VC=0
  export OSD=0

  case ${TARGET_ARCH} in
    arm|aarch64)
      PKG_MAKE_OPTS_TARGET+="-DNOHQ=On -DCRC_ARMV8=On -DEGL=On -DNEON_OPT=On"
    ;;
  esac

  export BINUTILS="$(get_build_dir binutils)/.${TARGET_NAME}"
  export APIDIR=$(get_install_dir mupen64plussa-core)/usr/local/include/mupen64plus
  export SDL_CFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -pthread -D_REENTRANT"
  export SDL_LDLIBS="-lSDL2_net -lSDL2"
  export CROSS_COMPILE="${TARGET_PREFIX}"

  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/src/CMakeLists.txt

  ./src/getRevision.sh
  cmake ${PKG_MAKE_OPTS_TARGET} \
    -DAPIDIR=${APIDIR} \
    -DMUPENPLUSAPI=On \
    -DGLIDEN64_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="${CC}" \
    -DCMAKE_CXX_COMPILER="${CXX}" \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS} -pthread" \
    -S src -B projects/cmake
  make clean -C projects/cmake
  make -Wno-unused-variable -C projects/cmake
}

makeinstall_target() {
  UPREFIX=${INSTALL}/usr/local
  ULIBDIR=${UPREFIX}/lib
  USHAREDIR=${UPREFIX}/share/mupen64plus
  UPLUGINDIR=${ULIBDIR}/mupen64plus
  mkdir -p ${UPLUGINDIR}
  cp ${PKG_BUILD}/projects/cmake/plugin/Release/mupen64plus-video-GLideN64.so \
     ${UPLUGINDIR}/mupen64plus-video-GLideN64.so
  chmod 0644 ${UPLUGINDIR}/mupen64plus-video-GLideN64.so

  mkdir -p ${USHAREDIR}
  cp ${PKG_BUILD}/ini/GLideN64.ini ${USHAREDIR}
  chmod 0644 ${USHAREDIR}/GLideN64.ini
}
