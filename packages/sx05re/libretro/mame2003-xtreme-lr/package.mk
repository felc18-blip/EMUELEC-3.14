# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="mame2003-xtreme-lr"
PKG_VERSION="9382b943f6a8a197d9fc8bd136d2c4a252c39b54"
PKG_SHA256="5fd17a0061166a91128364fe3b31144a1015132ef77b530aeb56734c6c0dd587"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MAME"
PKG_SITE="https://github.com/KMFDManic/mame2003-xtreme"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Updated 2018 version of MAME (0.78) for libretro, optimized for performance."
PKG_TOOLCHAIN="make"

pre_configure_target() {
  cd ${PKG_BUILD}

  # 🔥 VACINA GCC 15 + FIX DE INCLUDES:
  # Adicionamos -Isrc -Isrc/includes para ele não se perder
  # -fno-strict-aliasing resolve os erros de ponteiros que vimos no log
  export CFLAGS="$CFLAGS -fcommon -fno-strict-aliasing -std=gnu11 -Wno-error -Wno-implicit-function-declaration -Isrc -Isrc/includes -Isrc/libretro"
  export CXXFLAGS="$CXXFLAGS -fcommon -fno-strict-aliasing -std=gnu++11 -Wno-error -Isrc -Isrc/includes -Isrc/libretro"

  if [ "${ARCH}" = "aarch64" ]; then
      PKG_MAKE_OPTS_TARGET+=" platform=unix"
  else
      case ${DEVICE} in
        Amlogic-old) PKG_MAKE_OPTS_TARGET+=" platform=AMLGX" ;;
      esac
  fi

  PKG_MAKE_OPTS_TARGET+=" ARCH=\"\" CC=\"${CC}\" NATIVE_CC=\"${CC}\" LD=\"${CC}\""
}

make_target() {
  # Usamos nproc para detectar os núcleos ou fixamos em -j4 para segurança
  make ${PKG_MAKE_OPTS_TARGET} -j$(nproc)
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp km_mame2003_xtreme_amped_libretro.so ${INSTALL}/usr/lib/libretro/km_mame2003_xtreme_libretro.so
  cp km_mame2003_xtreme_libretro.info ${INSTALL}/usr/lib/libretro/km_mame2003_xtreme_libretro.info
}
