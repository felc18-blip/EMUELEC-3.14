# SPDX-License-Identifier: GPL-2.0
#
# NextOS Elite Edition — EKA2L1 Symbian/N-Gage emulator.
#
# Source: felc18-blip/eka2l1-nextos (fork of AveyondFly/EKA2L1 with the
# NextOS-specific build fixes — FFmpeg 8 compat, libMali EGL 1.4 _KHR
# aliases, no Wayland/X11/Vulkan, Qt frontend disabled, cmake 4 policy
# fixes — merged into the source tree as proper commits).

PKG_NAME="eka2l1"
PKG_VERSION="ce63efb7fc7f541179eb9787aa7b916c85f06380"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/felc18-blip/eka2l1-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="master"
PKG_GIT_SUBMODULES="yes"
PKG_DEPENDS_TARGET="toolchain SDL2 freetype zlib ffmpeg"
PKG_SECTION="emuelec/emulators"
PKG_SHORTDESC="Symbian OS / N-Gage emulator for aarch64 Linux"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="-lto"

PKG_CMAKE_OPTS_TARGET="
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  -DEKA2L1_BUILD_TESTS=OFF
  -DENABLE_TESTING=OFF
  -DENABLE_PROGRAMS=OFF
  -DEKA2L1_BUILD_SDL2_FRONTEND=ON
"

pre_configure_target() {
  # GCC 15 promotes several older warnings to errors in subprojects we
  # don't control (mbedtls, capstone, etc). Downgrade them.
  export CFLAGS="${CFLAGS} -Wno-error=unterminated-string-initialization -Wno-error=calloc-transposed-args -Wno-error"
  export CXXFLAGS="${CXXFLAGS} -Wno-error=unterminated-string-initialization -Wno-error=calloc-transposed-args -Wno-error"

  # capstone submodule still uses cmake_policy(SET CMP0048 OLD). CMake 4.x
  # removed OLD behavior for that policy and an explicit cmake_policy SET
  # overrides CMAKE_POLICY_DEFAULT_CMP0048, so we must edit the file.
  # The submodule is re-fetched on every unpack, so the edit is safe.
  CAPSTONE_CML="${PKG_BUILD}/src/external/capstone/CMakeLists.txt"
  if [ -f "${CAPSTONE_CML}" ]; then
    sed -i 's|cmake_policy *(SET CMP0048 OLD)|cmake_policy (SET CMP0048 NEW)|' "${CAPSTONE_CML}"
  fi
}

make_target() {
  # LuaJIT cross-compile needs a native buildvm; the upstream luajit-cmake
  # host chain fails under our sysroot, so we build minilua + buildvm by
  # hand with the host gcc targeting our guest arch.
  BUILD_DIR="${PKG_BUILD}/.${TARGET_NAME}"
  LUAJIT_SRC="${PKG_BUILD}/src/external/luajit/src"
  LUAJIT_CMAKE_BUILD="${BUILD_DIR}/src/external/luajit-cmake"
  MINILUA_BIN="${LUAJIT_CMAKE_BUILD}/minilua/minilua"
  BUILDVM_BIN="${LUAJIT_CMAKE_BUILD}/buildvm/buildvm"

  cd "${BUILD_DIR}"

  ninja minilua || true
  gcc "${LUAJIT_SRC}/host/minilua.c" -o "${MINILUA_BIN}" -lm
  ninja -t restat

  ninja buildvm || true
  gcc \
    -I"${LUAJIT_SRC}" \
    -I"${LUAJIT_CMAKE_BUILD}" \
    -DLUAJIT_TARGET=LUAJIT_ARCH_arm64 \
    -DLJ_ARCH_HASFPU=1 \
    -DLJ_ABI_SOFTFP=0 \
    -DLUAJIT_NUMMODE=2 \
    "${LUAJIT_SRC}/host/buildvm.c" \
    "${LUAJIT_SRC}/host/buildvm_asm.c" \
    "${LUAJIT_SRC}/host/buildvm_fold.c" \
    "${LUAJIT_SRC}/host/buildvm_lib.c" \
    "${LUAJIT_SRC}/host/buildvm_peobj.c" \
    -o "${BUILDVM_BIN}" -lm
  ninja -t restat

  ninja ${NINJA_OPTS} ${PKG_MAKE_OPTS_TARGET}
}

makeinstall_target() {
  BUILD_DIR="${PKG_BUILD}/.${TARGET_NAME}"

  mkdir -p "${INSTALL}/usr/bin/eka2l1"
  cp -a "${BUILD_DIR}/bin/." "${INSTALL}/usr/bin/eka2l1/"
  chmod +x "${INSTALL}/usr/bin/eka2l1/eka2l1_sdl2"

  cp "${PKG_DIR}/scripts/ekastart.sh" "${INSTALL}/usr/bin/ekastart.sh"
  chmod +x "${INSTALL}/usr/bin/ekastart.sh"

  mkdir -p "${INSTALL}/usr/config/emuelec/configs/eka2l1/gptk"
  cp -f "${PKG_DIR}/config/eka.gptk" "${INSTALL}/usr/config/emuelec/configs/eka2l1/gptk/eka.gptk"
}
