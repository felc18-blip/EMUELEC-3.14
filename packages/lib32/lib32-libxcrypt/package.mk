PKG_NAME="lib32-libxcrypt"
PKG_VERSION="$(get_pkg_version libxcrypt)"
PKG_NEED_UNPACK="$(get_pkg_directory libxcrypt)"
PKG_URL=""
PKG_ARCH="aarch64"

PKG_DEPENDS_TARGET="lib32-toolchain"
PKG_TOOLCHAIN="configure"
PKG_BUILD_FLAGS="lib32"

PKG_CONFIGURE_OPTS_TARGET="\
  --host=${LIB32_TARGET_NAME} \
  --build=${HOST_NAME} \
  --prefix=/usr \
  --libdir=/usr/lib32 \
  --enable-shared \
  --disable-static \
  --enable-hashes=all \
  --enable-obsolete-api=glibc \
  --disable-werror \
"
unpack() {
  ${SCRIPTS}/get libxcrypt
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/libxcrypt/libxcrypt-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}
makeinstall_target() {

  mkdir -p ${INSTALL}/usr/lib32
  mkdir -p ${LIB32_SYSROOT_PREFIX}/usr/lib
  mkdir -p ${LIB32_SYSROOT_PREFIX}/usr/include

  # copiar libs
  cp -P ${PKG_BUILD}/.${LIB32_TARGET_NAME}/.libs/libcrypt.so* \
        ${INSTALL}/usr/lib32/

  cp -P ${PKG_BUILD}/.${LIB32_TARGET_NAME}/.libs/libcrypt.so* \
        ${LIB32_SYSROOT_PREFIX}/usr/lib/

  # header
  cp -v ${PKG_BUILD}/.${LIB32_TARGET_NAME}/crypt.h \
        ${LIB32_SYSROOT_PREFIX}/usr/include/

  # symlink no sysroot
  ln -sf libcrypt.so.1 ${LIB32_SYSROOT_PREFIX}/usr/lib/libcrypt.so

  # 🔥 IMPORTANTE: symlink também no rootfs
  cd ${INSTALL}/usr/lib32
  ln -sf libcrypt.so.1 libcrypt.so
}