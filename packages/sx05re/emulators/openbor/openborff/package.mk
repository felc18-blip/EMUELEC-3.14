# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="openborff"
PKG_VERSION="3c14ffc37c984a5aebc7a3fb6133b47484d43bd2"
PKG_SHA256="275ba0593027053cfd9df0586868e1471b71153858dc0b42429938db07eba74c"
PKG_ARCH="any"
PKG_SITE="https://github.com/gonzalomvp/openbor"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2 libogg libvorbisidec libvpx libpng"
PKG_SHORTDESC="OpenBOR is the ultimate 2D side scrolling engine for beat em' ups, shooters, and more! "
PKG_LONGDESC="OpenBOR is the ultimate 2D side scrolling engine for beat em' ups, shooters, and more! "
PKG_TOOLCHAIN="make"

if [ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
  PKG_PATCH_DIRS="OdroidGoAdvance"
fi

if [[ "${ARCH}" == "arm" ]]; then
  PKG_PATCH_DIRS="${ARCH}"
else
  PKG_PATCH_DIRS="emuelec-aarch64"
fi

pre_configure_target() {
  PKG_MAKE_OPTS_TARGET="BUILD_LINUX_${ARCH}=1 \
                        -C ${PKG_BUILD}/engine \
                        SDKPATH=\"${SYSROOT_PREFIX}\" \
                        PREFIX=${TARGET_NAME}"
}

pre_make_target() {
  cd ${PKG_BUILD}/engine
  ./version.sh
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp $(find . -name "OpenBOR.elf" | head -n 1) ${INSTALL}/usr/bin/OpenBORff
  chmod +x ${INSTALL}/usr/bin/*
  mkdir -p ${INSTALL}/usr/config/emuelec/configs/openbor
  cp ${PKG_DIR}/config/master.cfg ${INSTALL}/usr/config/emuelec/configs/openbor/masterff.cfg
}

# FUNÇÃO DE LIMPEZA PESADA (RPATH e NEEDED)
post_makeinstall_target() {
  echo "--- Sanitizando binário do OpenBORff (Limpando rastros do PC) ---"
  find ${INSTALL}/usr/bin -type f -exec sh -c '
    # Remove RPATH/RUNPATH
    patchelf --remove-rpath "$1" 2>/dev/null
    
    # Substitui caminhos absolutos (/home/felipe/...) pelo nome puro da lib
    for lib_path in $(readelf -d "$1" 2>/dev/null | grep "NEEDED" | grep "/home/felipe" | sed -r "s/.*\[(.*)\].*/\1/"); do
      lib_name=$(basename "$lib_path")
      echo "  > Corrigindo dependência em OpenBORff: $lib_name"
      patchelf --replace-needed "$lib_path" "$lib_name" "$1" 2>/dev/null
    done
  ' _ {} \;
}