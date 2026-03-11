# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert
# Copyright (C) 2023 Nicholas Ricciuti
# Copyright (C) 2023 JELOS

PKG_NAME="mupen64plus-sa-core"
PKG_VERSION="b0d68c20f49b8f833afa21450e0e8874c87c13c4"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/mupen64plus/mupen64plus-core"
PKG_URL="https://github.com/mupen64plus/mupen64plus-core/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain boost libpng SDL2 SDL2_net zlib freetype nasm:host"
PKG_SHORTDESC="mupen64plus"
PKG_LONGDESC="Mupen64Plus Standalone"
PKG_TOOLCHAIN="manual"

if [ "${VULKAN_SUPPORT}" = "no" ]; then
  PKG_DEPENDS_TARGET+=" vulkan-loader vulkan-headers"
  export VULKAN=1
else
  export VULKAN=0
fi

case ${DEVICE} in
  AMD64)
    PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
    export USE_GLES=0
  ;;
  *)
    PKG_DEPENDS_TARGET+=" ${OPENGLES}"
    export USE_GLES=1
  ;;
esac

make_target() {

  export HOST_CPU=${TARGET_ARCH} \
         NEW_DYNAREC=1 \
         VFP_HARD=1 \
         V=1 \
         VC=0 \
         OSD=0

  export BINUTILS="$(get_build_dir binutils)/.${TARGET_NAME}"
  export SDL_CFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -pthread -D_REENTRANT"
  export SDL_LDLIBS="-lSDL2_net -lSDL2"
  export CROSS_COMPILE="${TARGET_PREFIX}"

  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/projects/unix/Makefile

  make -C projects/unix clean
  make -C projects/unix all ${PKG_MAKE_OPTS_TARGET}
}

makeinstall_target() {

  mkdir -p ${INSTALL}/usr/local/lib/mupen64plus-adv

  cp ${PKG_BUILD}/projects/unix/libmupen64plus.so.2.0.0 \
     ${INSTALL}/usr/local/lib/mupen64plus-adv/

  cp ${PKG_BUILD}/projects/unix/libmupen64plus.so.2 \
     ${INSTALL}/usr/local/lib/mupen64plus-adv/

  ln -sf libmupen64plus.so.2 \
     ${INSTALL}/usr/local/lib/mupen64plus-adv/libmupen64plus.so

  mkdir -p ${INSTALL}/usr/local/share/mupen64plus-adv
  cp ${PKG_BUILD}/data/* \
     ${INSTALL}/usr/local/share/mupen64plus-adv/

  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/scripts/start_mupen64plus-adv.sh \
     ${INSTALL}/usr/bin/start_mupen64plus-adv.sh
}