# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS

PKG_NAME="portmaster"
PKG_VERSION="2026.04.01-1426"
PKG_SITE="https://github.com/PortsMaster/PortMaster-GUI"
PKG_URL="${PKG_SITE}/releases/download/${PKG_VERSION}/PortMaster.zip"
COMPAT_URL="https://github.com/RetroGFX/UnofficialOSAddOns/raw/main/compat.zip"
PKG_LICENSE="MIT"
PKG_ARCH="arm aarch64"
PKG_DEPENDS_TARGET="toolchain gptokeyb gamecontrollerdb wget control-gen list-guid gst-plugins-base xmlstarlet"
PKG_TOOLCHAIN="manual"
PKG_LONGDESC="Portmaster - a simple tool that allows you to download various game ports "

makeinstall_target() {
  export STRIP=true

  # Diretório base do PortMaster
  mkdir -p ${INSTALL}/usr/config/PortMaster

  # Instala arquivos sources (control.txt / mapper.txt)
  if [ -d "${PKG_DIR}/sources" ]; then
    cp -rf ${PKG_DIR}/sources/* ${INSTALL}/usr/config/PortMaster/
  fi

  # Instala scripts executáveis
  mkdir -p ${INSTALL}/usr/bin
  if [ -d "${PKG_DIR}/scripts" ]; then
    cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
  fi

  chmod +x ${INSTALL}/usr/bin/* 2>/dev/null || true

  # Baixa o PortMaster
  mkdir -p ${INSTALL}/usr/config/PortMaster/release
  curl -L --retry 5 -o \
    ${INSTALL}/usr/config/PortMaster/release/PortMaster.zip \
    ${PKG_URL}

  # Compat libs usadas pelos ports
  mkdir -p ${INSTALL}/usr/lib/compat

  curl -L --retry 5 -o ${PKG_BUILD}/compat.zip ${COMPAT_URL}

  unzip -qq -o ${PKG_BUILD}/compat.zip \
      -d ${INSTALL}/usr/lib/compat/

  # Estrutura necessária do EmuELEC para gptokeyb
  mkdir -p ${INSTALL}/storage/.config/emuelec/configs/gptokeyb
}

post_install() {

case ${DEVICE} in
  Amlogic-old)
    LIBEGL=""
  ;;
  Amlogic-ng)
    LIBEGL=""
  ;;
  S922X)
    LIBEGL="SDL_VIDEO_GL_DRIVER=/usr/lib/egl/libGL.so.1 SDL_VIDEO_EGL_DRIVER=/usr/lib/egl/libEGL.so.1"
  ;;
  *)
    LIBEGL=""
  ;;
esac

  if [ -f "${INSTALL}/usr/bin/start_portmaster.sh" ]; then
    sed -e "s|@LIBEGL@|${LIBEGL}|g" \
        -i ${INSTALL}/usr/bin/start_portmaster.sh
  fi
}
