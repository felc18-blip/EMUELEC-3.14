# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="atari800sa"
PKG_VERSION="fcb6e799734c749f9e326640f4d506abf854e95c"
PKG_SHA256="e96cc007ab9115fe69f9e914813c7c3a5381885033f1ed4c35f21624bbb365c3"
PKG_SITE="https://github.com/atari800/atari800"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_SHORTDESC="Atari 8-bit computer and 5200 console emulator"
PKG_TOOLCHAIN="configure"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -f ${PKG_BUILD}/src/atari800 ${INSTALL}/usr/bin/atari800
  # NextOS: launcher script chamado pelo emuelecRunEmu.sh — wrapper p/
  # auto-config de BIOS + flags Mali-friendly (software rendering).
  cp -f ${PKG_DIR}/scripts/atari800.start ${INSTALL}/usr/bin/atari800.start
  chmod +x ${INSTALL}/usr/bin/atari800.start
}

pre_configure_target() {
  cd ${PKG_BUILD} && ./autogen.sh
  # NextOS: glibc 2.34+ moveu pthread_create() pra libc.so.6.
  # AC_CHECK_LIB([pthread]) tenta `-lpthread` e falha — bypass via cache var.
  export ac_cv_lib_pthread_pthread_create=yes
  export CFLAGS="${CFLAGS} -pthread"
  export LDFLAGS="${LDFLAGS} -pthread"
  # NextOS: AC_PATH_PROG(SDL2_CONFIG, sdl2-config, no) pega /usr/bin/
  # sdl2-config do HOST (que reporta -I/usr/include/SDL2) em vez do
  # sysroot do cross-toolchain. Forca o sysroot explicitamente.
  export SDL2_CONFIG="${SYSROOT_PREFIX}/usr/bin/sdl2-config"
}
