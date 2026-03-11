# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="nanoboyadvance-sa"
PKG_VERSION="3bb6f478f977dbfd3106508536e5fbce90d1898b"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/nba-emu/NanoBoyAdvance"
PKG_URL="${PKG_SITE}.git"
PKG_LONGDESC="NanoBoyAdvance is a cycle-accurate Game Boy Advance emulator."
PKG_TOOLCHAIN="cmake"
PKG_PATCH_DIRS+="${DEVICE}"

PKG_DEPENDS_TARGET="toolchain SDL2 glew glu"

# GLES (Amlogic / ES2)
if [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES} libdrm"
fi

PKG_CXXFLAGS+=" -Wno-error=array-bounds -Wno-error"

PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_BUILD_TYPE=Release \
                         -DCMAKE_INSTALL_PREFIX=/usr \
                         -DPLATFORM_SDL2=ON \
                         -DPLATFORM_QT=OFF \
                         -DUSE_OPENGL=ON \
                         -DUSE_OPENGLES=ON \
                         -DUSE_EGL=ON \
                         -DGLEW_USE_STATIC_LIBS=ON \
                         -DBUILD_SHARED_LIBS=OFF"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  install -m 0755 ${PKG_BUILD}/.${TARGET_NAME}/bin/sdl/NanoBoyAdvance \
      ${INSTALL}/usr/bin/NanoBoyAdvance

  mkdir -p ${INSTALL}/usr/config/nanoboyadvance
  cp -r ${PKG_DIR}/config/* \
      ${INSTALL}/usr/config/nanoboyadvance/

  install -m 0755 ${PKG_DIR}/scripts/start_nanoboyadvance.sh \
      ${INSTALL}/usr/bin/start_nanoboyadvance.sh
}