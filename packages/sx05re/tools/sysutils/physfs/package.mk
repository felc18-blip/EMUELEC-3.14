# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="physfs"
PKG_VERSION="0145431345058282ec77ffb4240b2f5947a7dc4a"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/criptych/physfs"
PKG_URL="$PKG_SITE.git"
PKG_DEPENDS_TARGET="toolchain glm ncurses"
PKG_SHORTDESC="PhysicsFS; a portable, flexible file i/o abstraction."
GET_HANDLER_SUPPORT="git"

PKG_TOOLCHAIN="cmake"

# Use PKG_CMAKE_OPTS_TARGET em vez de PKG_CONFIGURE_OPTS_TARGET
PKG_CMAKE_OPTS_TARGET="-DPHYSFS_BUILD_TEST=OFF \
                       -DCMAKE_EXE_LINKER_FLAGS=-ltinfow \
                       -DCMAKE_SHARED_LINKER_FLAGS=-ltinfow"