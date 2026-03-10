# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="dosbox-svn"
PKG_VERSION="53ca2f6303a652d129321cfc521f000cd7ec5531"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/dosbox-svn"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="libretro"

PKG_DEPENDS_TARGET="toolchain sdl12-compat SDL_net"
PKG_SECTION="libretro"
PKG_TOOLCHAIN="make"

pre_make_target() {
  cd ${PKG_BUILD}

  # baixar dependência correta
  if [ ! -d libretro/libretro-common ]; then
    git clone https://github.com/libretro/libretro-common.git libretro/libretro-common
  fi
}

make_target() {
  cd ${PKG_BUILD}

  # garantir includes
  cp libretro/libretro-common/include/libretro/* libretro/ 2>/dev/null || true

  if [ "${ARCH}" = "aarch64" ]; then
    make -C libretro target=arm64 WITH_EMBEDDED_SDL=0 WITH_FAKE_SDL=1
  elif [ "${ARCH}" = "arm" ]; then
    make -C libretro target=arm WITH_EMBEDDED_SDL=0 WITH_FAKE_SDL=1
  else
    make -C libretro WITH_EMBEDDED_SDL=0 WITH_FAKE_SDL=1
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/libretro/dosbox_svn_libretro.so ${INSTALL}/usr/lib/libretro
}