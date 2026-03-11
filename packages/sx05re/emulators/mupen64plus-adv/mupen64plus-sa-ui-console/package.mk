# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert
# Copyright (C) 2023 Nicholas Ricciuti
# Copyright (C) 2023 JELOS

PKG_NAME="mupen64plus-sa-ui-console"
PKG_VERSION="1340c4bdfc9ec53d3fccda5e085930dd79eb08b3"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/mupen64plus/mupen64plus-ui-console"
PKG_URL="https://github.com/mupen64plus/mupen64plus-ui-console/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libpng SDL2 SDL2_net zlib freetype nasm:host mupen64plus-sa-core"
PKG_SHORTDESC="mupen64plus-ui-console"
PKG_LONGDESC="Mupen64Plus Standalone Console"
PKG_TOOLCHAIN="manual"

case ${DEVICE} in
  AMD64|RK3588|S922X|RK3399)
    PKG_DEPENDS_TARGET+=" mupen64plus-sa-simplecore"
  ;;
esac

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

  export V=1 \
         VC=0

  export BINUTILS="$(get_build_dir binutils)/.${TARGET_NAME}"
  export APIDIR=$(get_build_dir mupen64plus-sa-core)/src/api
  export SDL_CFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -pthread -D_REENTRANT"
  export SDL_LDLIBS="-lSDL2_net -lSDL2"
  export CROSS_COMPILE="${TARGET_PREFIX}"

  make -C projects/unix clean

  make -C projects/unix all \
       COREDIR=/usr/local/lib/mupen64plus-adv/ \
       OPTFLAGS="-O3 -flto -Wl,-rpath,/usr/local/lib/mupen64plus-adv"

  cp ${PKG_BUILD}/projects/unix/mupen64plus \
     ${PKG_BUILD}/projects/unix/mupen64plus-base
}

makeinstall_target() {

  UPREFIX=${INSTALL}/usr/local
  ULIBDIR=${UPREFIX}/lib/mupen64plus-adv
  UBINDIR=${UPREFIX}/bin
  UMANDIR=${UPREFIX}/share/man
  UAPPSDIR=${UPREFIX}/share/applications
  UICONSDIR=${UPREFIX}/share/icons/hicolor

  mkdir -p ${UBINDIR}

  # Binário principal ADV
  cp ${PKG_BUILD}/projects/unix/mupen64plus-base \
     ${UBINDIR}/mupen64plus-adv
  chmod 0755 ${UBINDIR}/mupen64plus-adv

  if [ -e "${PKG_BUILD}/projects/unix/mupen64plus-simple" ]
  then
    cp ${PKG_BUILD}/projects/unix/mupen64plus-simple \
       ${UBINDIR}/mupen64plus-adv-simple
    chmod 0755 ${UBINDIR}/mupen64plus-adv-simple
  fi

  mkdir -p ${UMANDIR}/man6
  cp ${PKG_BUILD}/doc/mupen64plus.6 \
     ${UMANDIR}/man6/mupen64plus-adv.6
  chmod 0644 ${UMANDIR}/man6/mupen64plus-adv.6

  mkdir -p ${UAPPSDIR}
  cp ${PKG_BUILD}/data/mupen64plus.desktop \
     ${UAPPSDIR}/mupen64plus-adv.desktop
  chmod 0644 ${UAPPSDIR}/mupen64plus-adv.desktop

  mkdir -p ${UICONSDIR}/48x48/apps
  cp ${PKG_BUILD}/data/icons/48x48/apps/mupen64plus.png \
     ${UICONSDIR}/48x48/apps/mupen64plus-adv.png
  chmod 0644 ${UICONSDIR}/48x48/apps/mupen64plus-adv.png

  mkdir -p ${UICONSDIR}/scalable/apps
  cp ${PKG_BUILD}/data/icons/scalable/apps/mupen64plus.svg \
     ${UICONSDIR}/scalable/apps/mupen64plus-adv.svg
  chmod 0644 ${UICONSDIR}/scalable/apps/mupen64plus-adv.svg
}