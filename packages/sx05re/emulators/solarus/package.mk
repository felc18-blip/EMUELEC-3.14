# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="solarus"
PKG_VERSION="cc580fb399f720e241754ecc7817ce5d551d74d0"
PKG_ARCH="any"
PKG_LICENSE="GPLv3"
PKG_SITE="https://gitlab.com/solarus-games/solarus"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain luajit glm libmodplug physfs SDL2 SDL2_ttf SDL2_image openal-soft"
PKG_SHORTDESC="Action-RPG/Adventure 2D game engine"
PKG_TOOLCHAIN="cmake"
GET_HANDLER_SUPPORT="git"

pre_configure_target() {
  export LDFLAGS+=" -ldl"

  # 1. 🔥 CORREÇÃO DE PONTEIROS (GCC 15):
  # Forçamos o silenciamento dos erros de tipos incompatíveis que matam o build do Solarus
  export CXXFLAGS="${CXXFLAGS} -DGLM_ENABLE_EXPERIMENTAL -Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types -Wno-register"
  export CFLAGS="${CFLAGS} -Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types"

  # 2. 🔥 TRUQUE DO MODPLUG:
  # Em vez de definir UINT globalmente, vamos dizer ao Solarus para usar o stamin de tipos padrão do sistema
  # Isso evita o conflito com o stdafx.h da libmodplug
  export CXXFLAGS="${CXXFLAGS} -DHAVE_STDINT_H -DHAVE_INTTYPES_H"

  PKG_CMAKE_OPTS_TARGET="-DSOLARUS_GL_ES=ON \
                         -DSOLARUS_GUI=OFF \
                         -DSOLARUS_USE_LUAJIT=ON \
                         -DSOLARUS_TESTS=OFF \
                         -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
}

pre_makeinstall_target() {
mkdir -p ${INSTALL}/usr/bin
cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

mkdir -p ${INSTALL}/usr/config/emuelec/configs/solarus
cp ${PKG_DIR}/config/* ${INSTALL}/usr/config/emuelec/configs/solarus

}
