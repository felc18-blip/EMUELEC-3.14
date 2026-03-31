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
  --enable-obsolete-api \
  --disable-werror \
"

unpack() {
  ${SCRIPTS}/get libxcrypt
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/libxcrypt/libxcrypt-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

makeinstall_target() {

  # ===== instala no rootfs (lib32) =====
  make DESTDIR=${INSTALL} install

  # ===== instala no sysroot =====
  make DESTDIR=${LIB32_SYSROOT_PREFIX} install

  # ===== 🔥 GARANTE LIBS NO /usr/lib =====
  mkdir -p ${LIB32_SYSROOT_PREFIX}/usr/lib

  if [ -d ${LIB32_SYSROOT_PREFIX}/usr/lib32 ]; then
    cp -P ${LIB32_SYSROOT_PREFIX}/usr/lib32/libcrypt.so* \
          ${LIB32_SYSROOT_PREFIX}/usr/lib/
  fi

  # ===== 🔥 GARANTE SYMLINK =====
  if [ -f ${LIB32_SYSROOT_PREFIX}/usr/lib/libcrypt.so.1 ]; then
    ln -sf libcrypt.so.1 ${LIB32_SYSROOT_PREFIX}/usr/lib/libcrypt.so
  fi

  # ===== 💣 CORREÇÃO CRÍTICA (HEADER) =====
  mkdir -p ${LIB32_SYSROOT_PREFIX}/usr/include

  if [ -f ${INSTALL}/usr/include/crypt.h ]; then
    cp -f ${INSTALL}/usr/include/crypt.h \
          ${LIB32_SYSROOT_PREFIX}/usr/include/crypt.h
  fi
}