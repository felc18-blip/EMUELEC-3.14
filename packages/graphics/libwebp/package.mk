# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present EmuELEC (https://github.com/EmuELEC)

PKG_NAME="libwebp"
PKG_VERSION="e78e924f84ddcd41fc5d55583bc32f4ddc4100a3"
PKG_LICENSE="BSD"
PKG_SITE="https://github.com/webmproject/libwebp"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="WebP codec is a library to encode and decode images in WebP format."
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="+lto-parallel"
PKG_CMAKE_OPTS_TARGET=" -DBUILD_SHARED_LIBS=ON -DWEBP_BUILD_ANIM_UTILS=OFF -DWEBP_BUILD_WEBPINFO=OFF -DWEBP_BUILD_VWEBP=OFF -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_WEBPMUX=OFF -DWEBP_BUILD_IMG2WEBP=OFF -DWEBP_BUILD_EXTRAS=OFF -DWEBP_BUILD_DWEBP=OFF"
