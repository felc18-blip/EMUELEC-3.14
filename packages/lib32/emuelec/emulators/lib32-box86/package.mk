# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="lib32-box86"
PKG_VERSION="$(get_pkg_version box86)"
PKG_NEED_UNPACK="$(get_pkg_directory box86)"
PKG_ARCH="aarch64"
PKG_REV="1"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/ptitSeb/box86"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-gl4es"
PKG_PATCH_DIRS+=" $(get_pkg_directory box86)/patches"
PKG_LONGDESC="Box86 - Linux Userspace x86 Emulator for ARM"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="lib32"

if [ "${PROJECT}" = "Amlogic-ce" ]; then
  if [ "${DEVICE}" = "Amlogic-old" ]; then
    PKG_PATCH_DIRS+=" ${PROJECT_DIR}/Amlogic-ce/devices/Amlogic-old/patches/box86"
  fi
  PKG_CMAKE_OPTS_TARGET=" -DRK3399=ON -DCMAKE_BUILD_TYPE=Release"
else
  PKG_CMAKE_OPTS_TARGET=" -DGOA_CLONE=ON -DCMAKE_BUILD_TYPE=Release"
fi

unpack() {
  ${SCRIPTS}/get box86
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/box86/box86-${PKG_VERSION}.tar.gz -C ${PKG_BUILD}
}

pre_configure_target() {
  cd ${PKG_BUILD}

  # compatibilidade com kernel headers antigos (3.14)
  sed -i '1i\
#ifndef HWCAP2_PMULL\
#define HWCAP2_PMULL (1 << 1)\
#endif' src/main.c
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/config/emuelec/bin/box86/lib

  cp -r ${PKG_BUILD}/x86lib/* ${INSTALL}/usr/config/emuelec/bin/box86/lib

  # localizar o binário real
  BOX86_BIN=$(find ${PKG_BUILD} -name box86 -type f | head -n1)

  cp ${BOX86_BIN} ${INSTALL}/usr/config/emuelec/bin/box86/box86

  mkdir -p ${INSTALL}/etc/binfmt.d
  ln -sf /emuelec/configs/box86.conf ${INSTALL}/etc/binfmt.d/box86.conf
}