# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)
# Adaptado para EmuELEC 3.14 - Felipe

PKG_NAME="control-gen"
PKG_VERSION="75ade0f0344d2338968313ff346412fe5b1e4df0"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
# Garantimos a dependência da SDL2 para que os headers existam na build
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_SECTION="tools"
PKG_SHORTDESC="Generates control.txt for gptokeyb"
# Mudamos para manual para controlar o comando de compilação diretamente
PKG_TOOLCHAIN="manual"

make_target() {
  # Copia o código fonte para a pasta de construção
  cp -f ${PKG_DIR}/control-gen.cpp ${PKG_BUILD}

  # Comando de compilação forçando os caminhos do Sysroot do EmuELEC
  # Injetamos o include da SDL2 e linkamos a biblioteca explicitamente
  ${CXX} ${CXXFLAGS} ${LDFLAGS} \
         -I${SYSROOT_PREFIX}/usr/include/SDL2 \
         ${PKG_BUILD}/control-gen.cpp \
         -o ${PKG_BUILD}/control-gen \
         -lSDL2 -D_REENTRANT
}

makeinstall_target() {
  # 1. Instala o binário principal em /usr/bin
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/control-gen ${INSTALL}/usr/bin
  
  # 2. Instala os scripts de suporte (se existirem na pasta do pacote)
  if [ -d "${PKG_DIR}/scripts" ]; then
    cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
  fi
  
  # 3. Garante permissão de execução para todos os binários e scripts instalados
  chmod 0755 ${INSTALL}/usr/bin/*

  # 4. Cria a estrutura de pastas necessária para o EmuELEC 3.14 (visto na captura de tela)
  mkdir -p ${INSTALL}/storage/.config/emuelec/configs/gptokeyb
}