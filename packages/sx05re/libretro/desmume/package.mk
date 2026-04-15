################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
################################################################################

PKG_NAME="desmume"
PKG_VERSION="7f05a8d447b00acd9e0798aee97b4f72eb505ef9"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/desmume"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain libpcap"
PKG_LONGDESC="DeSmuME - Nintendo DS libretro"
PKG_TOOLCHAIN="make"

if [ "${OPENGL_SUPPORT}" = "yes" ] && [ ! "${PREFER_GLES}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu"

elif [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  PKG_PATCH_DIRS+=" gles"
fi


pre_configure_target() {
  cd ${PKG_BUILD}/desmume/src/frontend/libretro
  # Evita que o GCC 15 aborte por avisos bobos no código legado
  export CFLAGS="${CFLAGS} -Wno-error"
  export CXXFLAGS="${CXXFLAGS} -Wno-error"
}

make_target() {
  case ${ARCH} in
    arm)
      make CC=${CC} CXX=${CXX} platform=armv-unix-${TARGET_FLOAT}float-${TARGET_CPU}
      ;;
    aarch64)
      # Desativa explicitamente o JIT x86 que causa o erro de 'impossible constraint'
      make CC=${CC} CXX=${CXX} platform=unix-aarch64 DESMUME_JIT=0 DESMUME_JIT_ARM=0
      ;;
    x86_64)
      make CC=${CC} CXX=${CXX} platform=unix
      ;;
    *)
      make CC=${CC} CXX=${CXX} platform=unix DESMUME_JIT=0
      ;;
  esac
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp desmume_libretro.so ${INSTALL}/usr/lib/libretro/
}
