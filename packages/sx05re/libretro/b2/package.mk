PKG_NAME="b2"
PKG_VERSION="6485984cddf50e20fb7d9d5d350a9d54265c283c"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/zoltanvb/b2-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Adaptation of Tom Seddon's b2 emulator for BBC Micro"

PKG_TOOLCHAIN="make"

PKG_LIBRETRO="src/libretro"

pre_configure_target() {
  sed -i 's/size_t strlcpy(char \*dest, const char \*src, size_t size);/\/\/ removed: provided by glibc/' \
  ${PKG_BUILD}/src/shared/h/shared/system.h
}


pre_make_target() {
 
  cd ${PKG_BUILD}/${PKG_LIBRETRO}
}

make_target() {
  cd ${PKG_BUILD}/${PKG_LIBRETRO}
  make GIT_VERSION=${PKG_VERSION}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/${PKG_LIBRETRO}/b2_libretro.so ${INSTALL}/usr/lib/libretro/
}