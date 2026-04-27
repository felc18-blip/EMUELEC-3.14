# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="xz"
PKG_VERSION="5.8.3"
PKG_SHA256="fff1ffcf2b0da84d308a14de513a1aa23d4e9aa3464d17e64b9714bfdd0bbfb6"
PKG_LICENSE="GPL"
PKG_SITE="https://tukaani.org/xz/"
PKG_URL="https://github.com/tukaani-project/xz/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="ccache:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_BUILD_FLAGS="+pic +pic:host"
PKG_TOOLCHAIN="configure"

# NextOS-Elite-Edition: build BOTH static + shared liblzma so Python3 can
# detect it during build (otherwise _lzma module is silently skipped and
# anything trying to read .tar.xz crashes with "lzma module is not
# available" — broke PortMaster which extracts NotoSans.tar.xz on launch).
# Drop --disable-shared and the post_makeinstall_target rm-rf hack that
# wiped ${INSTALL} (those came from a bulk bump and made xz a host-only
# package, breaking the target sysroot install).
PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --enable-shared \
                           --disable-doc \
                           --disable-lzmadec \
                           --disable-lzmainfo \
                           --disable-lzma-links \
                           --disable-scripts \
                           --disable-xz \
                           --disable-xzdec \
                           --enable-symbol-versions=no"
