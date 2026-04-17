PKG_NAME="lib32-libpciaccess"
PKG_VERSION="$(get_pkg_version libpciaccess)"
PKG_NEED_UNPACK="$(get_pkg_directory libpciaccess)"
PKG_LICENSE="OSS"
PKG_SITE="http://freedesktop.org"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-util-macros lib32-zlib"
PKG_LONGDESC="X.org libpciaccess library."
PKG_PATCH_DIRS+=" $(get_pkg_directory libpciaccess)/patches"
PKG_BUILD_FLAGS="lib32"

PKG_TOOLCHAIN="meson"

PKG_MESON_OPTS_TARGET="-Dpci-ids=/usr/share \
                       -Dzlib=enabled"

unpack() {
  ${SCRIPTS}/get libpciaccess
  mkdir -p ${PKG_BUILD}

  SRC=$(ls ${SOURCES}/libpciaccess/*.tar.* | head -n1)
  tar --strip-components=1 -xf ${SRC} -C ${PKG_BUILD}
}

pre_configure_target() {
  CFLAGS+=" -D_LARGEFILE64_SOURCE"
}

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/include
  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}
