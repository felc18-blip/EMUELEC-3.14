# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="lib32-bennugd-monolithic"
PKG_VERSION="$(get_pkg_version bennugd-monolithic)"
PKG_NEED_UNPACK="$(get_pkg_directory bennugd-monolithic)"
PKG_ARCH="aarch64"
PKG_SITE="https://github.com/christianhaitian/bennugd-monolithic"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-libvorbisidec lib32-SDL2 lib32-SDL3_mixer lib32-libpng lib32-tre"
PKG_PATCH_DIRS+=" $(get_pkg_directory bennugd-monolithic)/patches"
PKG_SHORTDESC="Use for executing bennugd games like Streets of Rage Remake "
PKG_TOOLCHAIN="cmake-make"
PKG_BUILD_FLAGS="lib32"

unpack() {
  ${SCRIPTS}/get bennugd-monolithic
  mkdir -p ${PKG_BUILD}
  tar cf - -C ${SOURCES}/bennugd-monolithic/bennugd-monolithic-${PKG_VERSION} ${PKG_TAR_COPY_OPTS} . | tar xf - -C ${PKG_BUILD}
}

pre_configure_target() {
  chainfile="cmake-${TARGET_NAME}.conf"

  # --- VACINA GCC 15 ---
  # Como a compilação é manual, injetamos as permissividades direto em uma variável
  # para passar dentro de cada cmake abaixo.
  VACCINE="-std=gnu11 -Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types -Wno-error=int-conversion -Wno-int-conversion -Wno-implicit-function-declaration -Wno-return-type"

  echo ">>> Compilando o BGDC..."
  PKG_CMAKE_SCRIPT="${PKG_BUILD}/projects/cmake/bgdc/CMakeLists.txt"
  cd ${PKG_BUILD}/projects/cmake/bgdc/
  cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN}/etc/${chainfile} \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_C_FLAGS="${CFLAGS} ${VACCINE}" \
        -DCMAKE_CXX_FLAGS="${CXXFLAGS} ${VACCINE}" \
        ${PKG_CMAKE_SCRIPT}
  make

  echo ">>> Compilando o BGDI..."
  PKG_CMAKE_SCRIPT="${PKG_BUILD}/projects/cmake/bgdi/CMakeLists.txt"
  cd ${PKG_BUILD}/projects/cmake/bgdi/
  cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN}/etc/${chainfile} \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_C_FLAGS="${CFLAGS} ${VACCINE}" \
        -DCMAKE_CXX_FLAGS="${CXXFLAGS} ${VACCINE}" \
        ${PKG_CMAKE_SCRIPT}
  make
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/projects/cmake/bgdi/bgdi ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/projects/cmake/bgdc/bgdc ${INSTALL}/usr/bin
}
