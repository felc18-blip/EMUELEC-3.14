# SPDX-License-Identifier: GPL-2.0-or-later
# Fake EGL wrapper (isolado, não interfere no EGL real)

PKG_NAME="libegl-fake"
PKG_VERSION="1.0"
PKG_LICENSE="GPLv2"
PKG_ARCH="arm aarch64"
PKG_DEPENDS_TARGET="toolchain"
PKG_TOOLCHAIN="manual"
PKG_LONGDESC="Fake EGL wrapper for testing OpenGL compatibility (non-invasive)."

makeinstall_target() {
  export STRIP=true

  mkdir -p ${INSTALL}/usr/lib/egl

  # extrai libs
  tar -xvf ${PKG_DIR}/sources/libegl.tar.gz -C ${INSTALL}/usr/lib/egl

  # garante symlink do EGL
  if [ -f ${INSTALL}/usr/lib/egl/libEGL.so.1 ]; then
    ln -sf libEGL.so.1 ${INSTALL}/usr/lib/egl/libEGL.so
  fi

  # evita conflito com gl4es (renomeia libGL se existir)
  if [ -f ${INSTALL}/usr/lib/egl/libGL.so.1 ]; then
    mv ${INSTALL}/usr/lib/egl/libGL.so.1 ${INSTALL}/usr/lib/egl/libGL_fake.so.1
  fi
}