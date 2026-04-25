# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)
# NextOS: portado de make->meson (upstream e4b1823+ usa meson)

PKG_NAME="sundog"
PKG_VERSION="e4b1823ea832aea7aca27e94968665be615c8468"
PKG_SHA256="5449cdb241a6c2a464fdd42cb8723bc87d1afbeb2f4f1ba3ae0d2d00645d3855"
PKG_ARCH="any"
PKG_SITE="https://github.com/laanwj/sundog"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2 Python3:host"
PKG_LONGDESC="A port of the Atari ST game SunDog: Frozen Legacy (1984) by FTL software"
PKG_TOOLCHAIN="meson"

pre_configure_target() {
  PKG_MESON_OPTS_TARGET="\
    -Dpsys_debugger=false \
    -Ddebug_ui=false \
    -Dgame_cheats=false \
    -Dbuiltin_image=false"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -f ${PKG_BUILD}/.${TARGET_NAME}/src/sundog ${INSTALL}/usr/bin/sundog || \
    cp -f ${PKG_BUILD}/.${TARGET_NAME}/sundog ${INSTALL}/usr/bin/sundog
}
