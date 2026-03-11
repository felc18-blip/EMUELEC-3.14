PKG_NAME="minivmac-lr"
PKG_VERSION="2eb65cd5ca80174435867d2453d702390e5aab45"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/libretro-minivmac"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libretro-common"
PKG_SECTION="libretro"
PKG_TOOLCHAIN="make"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp minivmac_libretro.so ${INSTALL}/usr/lib/libretro/
}