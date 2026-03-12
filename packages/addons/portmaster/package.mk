# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="portmaster"
PKG_VERSION="2026.01.19-0955"
PKG_SITE="https://github.com/PortsMaster/PortMaster-GUI"
PKG_URL="${PKG_SITE}/releases/download/${PKG_VERSION}/PortMaster.zip"
COMPAT_URL="https://github.com/RetroGFX/UnofficialOSAddOns/raw/main/compat.zip"
PKG_LICENSE="MIT"
PKG_ARCH="arm aarch64"
# ADICIONADO: unzip e libmali | REMOVIDO: oga_controls
PKG_DEPENDS_TARGET="toolchain gptokeyb gamecontrollerdb wget control-gen unzip libmali"
PKG_TOOLCHAIN="manual"
PKG_LONGDESC="Portmaster - a simple tool that allows you to download various game ports"

makeinstall_target() {
  export STRIP=true
  mkdir -p ${INSTALL}/usr/config/PortMaster
  
  # Verifica se a pasta sources existe antes de copiar
  if [ -d "${PKG_DIR}/sources" ]; then
    cp -rf ${PKG_DIR}/sources/* ${INSTALL}/usr/config/PortMaster/
  fi

  mkdir -p ${INSTALL}/usr/bin
  if [ -d "${PKG_DIR}/scripts" ]; then
    cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  fi
  chmod +x ${INSTALL}/usr/bin/*

  # Baixa o Zip do PortMaster
  mkdir -p ${INSTALL}/usr/config/PortMaster/release
  curl -Lo ${INSTALL}/usr/config/PortMaster/release/PortMaster.zip ${PKG_URL}

  # Baixa e EXTRAI as libs de compatibilidade (aqui o unzip entra em ação)
  mkdir -p ${INSTALL}/usr/lib/compat
  curl -Lo ${PKG_BUILD}/compat.zip ${COMPAT_URL}
  unzip -qq -o ${PKG_BUILD}/compat.zip -d ${INSTALL}/usr/lib/compat/
  
  # 5. AJUSTE: Garante que a pasta de configs do EmuELEC exista
  mkdir -p ${INSTALL}/storage/.config/emuelec/configs/gptokeyb
}

post_install() {
    case ${DEVICE} in
      Amlogic-old)
        # Caminhos específicos para a Mali-450 do S905L
        LIBEGL="export SDL_VIDEO_GL_DRIVER=/usr/lib/libGLESv2.so export SDL_VIDEO_EGL_DRIVER=/usr/lib/libEGL.so"
      ;;
      S922X)
        LIBEGL="export SDL_VIDEO_GL_DRIVER=/usr/lib/egl/libGL.so.1 export SDL_VIDEO_EGL_DRIVER=/usr/lib/egl/libEGL.so.1"
      ;;
      *)
        LIBEGL=""
      ;;
    esac
    
    if [ -f "${INSTALL}/usr/bin/start_portmaster.sh" ]; then
      # MUDANÇA AQUI: Trocamos o / por | para evitar erro com caminhos de arquivos
      sed -e "s|@LIBEGL@|${LIBEGL}|g" \
          -i ${INSTALL}/usr/bin/start_portmaster.sh
    fi
}