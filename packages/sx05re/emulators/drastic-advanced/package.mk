# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="drastic-advanced"
PKG_VERSION="260120"
PKG_LICENSE="Proprietary"
PKG_ARCH="aarch64"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Install Drastic Advanced with persistent storage"
PKG_TOOLCHAIN="manual"

if [ "${DEVICE}" = "S922X" ]; then
  PKG_DEPENDS_TARGET+=" libegl"
fi

make_target() {
  :
}

makeinstall_target() {

  # Launcher
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/advancedrastic.sh \
         ${INSTALL}/usr/bin/advancedrastic.sh
  chmod +x ${INSTALL}/usr/bin/advancedrastic.sh

  # Instala separado do drastic normal
  mkdir -p ${INSTALL}/usr/config/drastic-advanced
  cp -rf ${PKG_DIR}/advanced_drastic/* \
         ${INSTALL}/usr/config/drastic-advanced/

  chmod +x ${INSTALL}/usr/config/drastic-advanced/drastic
}

post_install() {
    case ${DEVICE} in
      S922X)
        LIBEGL="export SDL_VIDEO_GL_DRIVER=\/usr\/lib\/egl\/libGL.so.1 SDL_VIDEO_EGL_DRIVER=\/usr\/lib\/egl\/libEGL.so.1"
      ;;
      RK3588)
        LIBEGL=""
      ;;
      *)
        LIBEGL=""
      ;;
    esac

    sed -e "s/@LIBEGL@/${LIBEGL}/g" \
        -i ${INSTALL}/usr/bin/advancedrastic.sh
}