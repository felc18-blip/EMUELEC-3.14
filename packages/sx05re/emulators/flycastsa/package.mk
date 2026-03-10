# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="flycastsa"
PKG_VERSION="bf2bd7efed41e9f3367a764c2d90fcaa9c38a1f9"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/flyinghead/flycast"
PKG_URL="${PKG_SITE}.git"

PKG_GIT_CLONE_BRANCH="master"
PKG_GIT_CLONE_SUBMODULES="yes"

PKG_DEPENDS_TARGET="toolchain ${OPENGLES} alsa SDL2 libzip zip"
PKG_LONGDESC="Flycast Dreamcast/Naomi/Atomiswave emulator"
PKG_TOOLCHAIN="cmake"
GET_HANDLER_SUPPORT="git"

if [ "${ARCH}" = "arm" ]; then
  PKG_PATCH_DIRS="arm"
fi

pre_patch() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive
}
pre_configure_target() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive

  export CXXFLAGS="${CXXFLAGS} -Wno-error=array-bounds"
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_GLES=ON -DUSE_VULKAN=OFF -DUSE_HOST_SDL=ON"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin

  cp ${PKG_BUILD}/flycast ${INSTALL}/usr/bin/flycast
  cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

  chmod +x ${INSTALL}/usr/bin/flycast.sh
  chmod +x ${INSTALL}/usr/bin/set_flycast_joy.sh
}