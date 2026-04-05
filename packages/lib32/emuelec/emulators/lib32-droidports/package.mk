# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="lib32-droidports"
PKG_VERSION="$(get_pkg_version droidports)"
PKG_NEED_UNPACK="$(get_pkg_directory droidports)"
PKG_ARCH="aarch64"
PKG_SITE="https://github.com/JohnnyonFlame/droidports"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-SDL2 lib32-SDL2_image lib32-openal-soft lib32-bzip2 lib32-libzip lib32-libpng lib32-freetype"
PKG_PATCH_DIRS+=" $(get_pkg_directory droidports)/patches"
PKG_LONGDESC="A repository for experimenting with elf loading and in-place patching of android native libraries on non-android operating systems."
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="lib32"

PKG_CMAKE_OPTS_TARGET=" \
  -DCMAKE_BUILD_TYPE=Release \
  -DPLATFORM=linux \
  -DPORT=gmloader \
  -DUSE_BUILTIN_FREETYPE=OFF \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5"

unpack() {
  ${SCRIPTS}/get droidports
  mkdir -p ${PKG_BUILD}
  tar cf - -C ${SOURCES}/droidports/droidports-${PKG_VERSION} ${PKG_TAR_COPY_OPTS} . | tar xf - -C ${PKG_BUILD}
}

pre_configure_target() {

  # --- FIX 1: bug real libyoyo ---
  sed -i 's/get_platform_savedir(gamename)/get_platform_savedir()/g' \
    ${PKG_BUILD}/ports/gmloader/libyoyo.c

  # --- FIX 2: remove freetype interno quebrado ---
  sed -i '/add_subdirectory(3rdparty\/freetype)/d' \
    ${PKG_BUILD}/3rdparty/CMakeLists.txt

  # --- FIX 3: remove flags ARM antigas inválidas ---
  find ${PKG_BUILD} -type f \( -name "*.cmake" -o -name "*.txt" \) -exec sed -i \
    -e 's/-mcpu=cortex-a9//g' \
    -e 's/-mfpu=vfpv3-d16//g' \
    -e 's/-mfpu=neon//g' \
    -e 's/-mthumb//g' {} +

  # --- FIX 4: GCC moderno ---
  export CFLAGS="${CFLAGS} \
    -std=gnu11 \
    -Wno-error \
    -Wno-incompatible-pointer-types \
    -Wno-int-conversion \
    -Wno-return-type \
    -Wno-implicit-function-declaration \
    -Wno-discarded-qualifiers \
    -Wno-strict-aliasing"

  export CXXFLAGS="${CXXFLAGS} \
    -std=gnu++11 \
    -Wno-error"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin

  if [ -f ${PKG_BUILD}/.${TARGET_NAME}/gmloader ]; then
    cp ${PKG_BUILD}/.${TARGET_NAME}/gmloader ${INSTALL}/usr/bin
  else
    find ${PKG_BUILD} -name gmloader -exec cp {} ${INSTALL}/usr/bin/ \;
  fi

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/gmloader
  cp -rf $(get_pkg_directory droidports)/config/* ${INSTALL}/usr/config/emuelec/configs/gmloader/
  cp -rf $(get_pkg_directory droidports)/scripts/* ${INSTALL}/usr/bin/
}
