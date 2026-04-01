# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="dtc"
PKG_VERSION="1.6.1"
PKG_SHA256="264d355e2e547a4964d55b83b113f89be1aea5e61dbe0547ab798d0fde2be180"
PKG_LICENSE="GPL"
PKG_SITE="https://git.kernel.org/pub/scm/utils/dtc/dtc.git/"
PKG_URL="https://git.kernel.org/pub/scm/utils/dtc/dtc.git/snapshot/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="toolchain:host zlib:host"
PKG_DEPENDS_TARGET="toolchain zlib"
PKG_LONGDESC="The Device Tree Compiler"
PKG_TOOLCHAIN="make"

# Desativamos o WERROR aqui para evitar o erro de discarded-qualifiers no Arch
PKG_MAKE_OPTS_TARGET="dtc fdtput fdtget fdtdump libfdt WERROR=0"
PKG_MAKE_OPTS_HOST="dtc libfdt WERROR=0"

post_patch() {
  echo "--- REMOVENDO RIGOR DO COMPILADOR PARA O ARCH LINUX ---"
  # Uma marreta extra: removemos o -Werror direto do Makefile se ele ignorar a flag de cima
  sed -i 's/-Werror//g' Makefile
}

pre_configure_host() {
  export LDLIBS_dtc="-lz"
  # Adicionamos -Wno-error para garantir que avisos fiquem apenas como avisos
  export EXTRA_CFLAGS="-I${TOOLCHAIN}/include -Wno-error"
}

pre_make_host() {
  mkdir -p ${PKG_BUILD}/.${HOST_NAME}
  cp -a ${PKG_BUILD}/* ${PKG_BUILD}/.${HOST_NAME}
  # Note: o sistema de build do LibreELEC/EmuELEC geralmente cuida do cd,
  # mas se você forçar o cd aqui, use caminhos absolutos ou variáveis.
}

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/bin
  cp -P ${PKG_BUILD}/.${HOST_NAME}/dtc ${TOOLCHAIN}/bin
  mkdir -p ${TOOLCHAIN}/lib
  # Verificamos se os arquivos existem antes de copiar para evitar erro de build
  [ -f ${PKG_BUILD}/.${HOST_NAME}/libfdt/libfdt.so ] && cp -P ${PKG_BUILD}/.${HOST_NAME}/libfdt/{libfdt.so,libfdt.so.1} ${TOOLCHAIN}/lib || true
}

pre_make_target() {
  mkdir -p ${PKG_BUILD}/.${TARGET_NAME}
  cp -a ${PKG_BUILD}/* ${PKG_BUILD}/.${TARGET_NAME}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/dtc ${INSTALL}/usr/bin
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/fdtput ${INSTALL}/usr/bin/
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/fdtget ${INSTALL}/usr/bin
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/fdtdump ${INSTALL}/usr/bin/

  mkdir -p ${INSTALL}/usr/lib
  mkdir -p ${SYSROOT_PREFIX}/usr/include

  # Instalando a lib estática e headers no sysroot para o u-boot-tools encontrar
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/libfdt/libfdt.a ${SYSROOT_PREFIX}/usr/lib
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/libfdt/fdt.h ${SYSROOT_PREFIX}/usr/include
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/libfdt/libfdt.h ${SYSROOT_PREFIX}/usr/include
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/libfdt/libfdt_env.h ${SYSROOT_PREFIX}/usr/include
}
