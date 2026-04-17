PKG_NAME="b2"
PKG_VERSION="b16e3a4a91fed4d6d2ccb227211119da7b39c8d1"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/zoltanvb/b2-libretro"
PKG_URL="https://github.com/zoltanvb/b2-libretro/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain util-linux"
PKG_LONGDESC="Adaptation of Tom Seddon's b2 emulator for BBC Micro"

PKG_TOOLCHAIN="make"

make_target() {
  cd ${PKG_BUILD}/src/libretro
  make -j$(getconf _NPROCESSORS_ONLN) clean
  make -j$(getconf _NPROCESSORS_ONLN)
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp b2_libretro.so ${INSTALL}/usr/lib/libretro/
}
