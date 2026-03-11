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
PKG_LONGDESC="Updated 2018 version of MAME (0.78) for libretro, with added game support, and optimized for performance and speed on the Mini Classics. "
PKG_TOOLCHAIN="make"

pre_configure_target() {
  cd ${PKG_BUILD}
  export SYSROOT_PREFIX=${SYSROOT_PREFIX}

  # Se for 64 bits, usamos a plataforma unix que é mais limpa, 
  # ou forçamos a remoção das flags de 32 bits.
  if [ "${ARCH}" = "aarch64" ]; then
      PKG_MAKE_OPTS_TARGET+=" platform=unix"
  else
      case ${DEVICE} in
        Amlogic-ng|Amlogic-no|Amlogic-ogu)
            PKG_MAKE_OPTS_TARGET+=" platform=AMLG12B"
          ;;
        Amlogic-old)
            PKG_MAKE_OPTS_TARGET+=" platform=AMLGX"
          ;;
      esac
  fi

  PKG_MAKE_OPTS_TARGET+=" ARCH=\"\" CC=\"${CC}\" NATIVE_CC=\"${CC}\" LD=\"${CC}\""
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  # Note que mudamos o nome da origem para bater com o que o erro mostrou
  cp km_mame2003_xtreme_amped_libretro.so ${INSTALL}/usr/lib/libretro/km_mame2003_xtreme_libretro.so
  cp km_mame2003_xtreme_libretro.info ${INSTALL}/usr/lib/libretro/km_mame2003_xtreme_libretro.info
}
