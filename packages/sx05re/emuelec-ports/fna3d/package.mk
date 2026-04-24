# SPDX-License-Identifier: GPL-2.0-or-later
# FNA3D — GLES2 native build for Mali 400-series (NextOS-Elite-Edition)

PKG_NAME="fna3d"
PKG_VERSION="24.02"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="ZLIB"
PKG_SITE="https://fna-xna.github.io/"
# Use a "dummy" URL; real fetch happens in pre_configure_target via git clone
# with submodules (submodule commits only satisfiable via git).
PKG_URL="https://github.com/FNA-XNA/FNA3D/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="FNA3D-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_SHORTDESC="FNA3D — patched for GLES2 native on Mali-450"
PKG_LONGDESC="FNA3D is the 3D graphics library for FNA. Build patched to accept OpenGL ES 2.0 contexts via gl4es on Amlogic S905x Mali-450 hardware."
PKG_TOOLCHAIN="cmake"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5"

pre_configure_target() {
  cd "${PKG_BUILD}"

  # The FNA3D tarball lacks submodules. Fetch them via git matching tag 24.02.
  if [ ! -f "${PKG_BUILD}/MojoShader/mojoshader.c" ] || \
     [ ! -f "${PKG_BUILD}/Vulkan-Headers/include/vulkan/vulkan.h" ]; then
    rm -rf "${PKG_BUILD}.gitclone"
    git clone --depth 1 --branch "${PKG_VERSION}" \
      https://github.com/FNA-XNA/FNA3D.git "${PKG_BUILD}.gitclone"
    ( cd "${PKG_BUILD}.gitclone" && \
      git submodule update --init --recursive --depth 1 )
    rm -rf "${PKG_BUILD}/MojoShader" "${PKG_BUILD}/Vulkan-Headers"
    cp -r "${PKG_BUILD}.gitclone/MojoShader" "${PKG_BUILD}/"
    cp -r "${PKG_BUILD}.gitclone/Vulkan-Headers" "${PKG_BUILD}/"
    rm -rf "${PKG_BUILD}.gitclone"
  fi

  # NextOS: clone Google astc-codec for CPU ASTC decode on Mali-400/450
  if [ ! -d "${PKG_BUILD}/astc-codec" ]; then
    git clone --depth 1 \
      https://github.com/google/astc-codec.git "${PKG_BUILD}/astc-codec"
  fi
}

makeinstall_target() {
  # FNA3D 24.02 CMakeLists has no install target; install manually.
  mkdir -p "${INSTALL}/usr/lib" "${INSTALL}/usr/include"
  cp -a "${PKG_BUILD}/libFNA3D.so"* "${INSTALL}/usr/lib/"
  cp -a "${PKG_BUILD}/include/"*.h "${INSTALL}/usr/include/" 2>/dev/null || true
}
