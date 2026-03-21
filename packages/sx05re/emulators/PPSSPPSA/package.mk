# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="PPSSPPSA"
PKG_REV="1"
PKG_ARCH="any"
PKG_SITE="https://github.com/hrydgard/ppsspp"
PKG_URL="${PKG_SITE}.git"
PKG_VERSION="afbc66a318b86432642b532c575241f3716642ef" # v1.20.2
CHEAT_DB_VERSION="7c9fe1ae71155626cea767aed53f968de9f4051f" # Update cheat.db (17/01/2026)
PKG_LICENSE="GPLv2"
PKG_DEPENDS_TARGET="toolchain libzip SDL2 zlib zip"
PKG_SHORTDESC="PPSSPPDL"
PKG_LONGDESC="PPSSPP Standalone"
GET_HANDLER_SUPPORT="git"

### Note:
### This package includes the NotoSansJP-Regular.ttf font.  This font is licensed under
### SIL Open Font License, Version 1.1.  The license can be found in the licenses
### directory in the root of this project, OFL.txt.
###

PKG_PATCH_DIRS+="${DEVICE}"

PKG_CMAKE_OPTS_TARGET=" -DUSE_SYSTEM_FFMPEG=OFF \
                        -DCMAKE_BUILD_TYPE=Release \
                        -DCMAKE_SYSTEM_NAME=Linux \
                        -DBUILD_SHARED_LIBS=OFF \
                        -DUSE_SYSTEM_LIBPNG=OFF \
                        -DANDROID=OFF \
                        -DWIN32=OFF \
                        -DAPPLE=OFF \
                        -DCMAKE_CROSSCOMPILING=ON \
                        -DUSING_QT_UI=OFF \
                        -DUNITTEST=OFF \
                        -DSIMULATOR=OFF \
                        -DHEADLESS=OFF \
                        -DUSE_DISCORD=OFF"

if [[ "${OPENGL_SUPPORT}" = "yes" ]] && [[ ! "${DEVICE}" = "S922X" ]]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd glew"
  PKG_CMAKE_OPTS_TARGET+=" -DUSING_FBDEV=OFF \
                           -DUSING_GLES2=OFF"

elif [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  PKG_CMAKE_OPTS_TARGET+=" -DUSING_FBDEV=ON \
                           -DUSING_EGL=OFF \
                           -DUSING_GLES2=ON"
fi

if [ "${VULKAN_SUPPORT}" = "yes" ]
then
  PKG_DEPENDS_TARGET+=" vulkan-loader vulkan-headers"
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_VULKAN_DISPLAY_KHR=ON \
                           -DVULKAN=ON \
                           -DEGL_NO_X11=1 \
                           -DMESA_EGL_NO_X11_HEADERS=1"
else
  PKG_CMAKE_OPTS_TARGET+=" -DVULKAN=OFF \
                           -DUSE_VULKAN_DISPLAY_KHR=OFF \
                           -DUSING_X11_VULKAN=OFF"
fi

if [ "${DISPLAYSERVER}" = "wl" ]; then
  PKG_DEPENDS_TARGET+=" wayland ${WINDOWMANAGER}"
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_WAYLAND_WSI=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_WAYLAND_WSI=OFF"
fi

pre_configure_target() {
  sed -i 's/\-O[23]//g' ${PKG_BUILD}/CMakeLists.txt
  sed -i "s|include_directories(/usr/include/drm)|include_directories(${SYSROOT_PREFIX}/usr/include/drm)|" ${PKG_BUILD}/CMakeLists.txt
}

pre_make_target() {
  export CPPFLAGS="${CPPFLAGS} -Wno-error"
  export CFLAGS="${CFLAGS} -Wno-error"

  # fix cross compiling
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}

makeinstall_target() {
  # 1. Estrutura de diretórios
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/config/ppsspp-sa/assets
  mkdir -p ${INSTALL}/usr/config/ppsspp-sa/PSP/SYSTEM
  mkdir -p ${INSTALL}/usr/config/ppsspp-sa/PSP/Cheats

  # 2. Copia os scripts com os nomes CORRETOS que estão na sua raiz
  # Conforme sua captura de tela: start_ppsspp.sh e psp_save_mover.sh
  cp -f ${PKG_DIR}/start_ppsspp.sh ${INSTALL}/usr/bin/start_ppsspp.sh
  cp -f ${PKG_DIR}/psp_save_mover.sh ${INSTALL}/usr/bin/psp_save_mover.sh

  # 3. Copia o binário (ele foi gerado como PPSSPPSDL no log de build)
  cp -f PPSSPPSDL ${INSTALL}/usr/bin/PPSSPPSA

  # 4. Permissões
  chmod 0755 ${INSTALL}/usr/bin/*

  # 5. Assets (usando o método mais seguro de busca)
  ASSETS_DIR=$(find . -maxdepth 2 -type d -name "assets" | head -n1)
  if [ -n "$ASSETS_DIR" ]; then
    cp -rf ${ASSETS_DIR}/* ${INSTALL}/usr/config/ppsspp-sa/assets/
  fi

  # 6. Configs locais
  if [ -d "${PKG_DIR}/config" ]; then
    cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/ppsspp-sa/
  fi

  # 7. Limpezas e Links
  rm -f ${INSTALL}/usr/config/ppsspp-sa/assets/gamecontrollerdb.txt
  ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt \
         ${INSTALL}/usr/config/ppsspp-sa/assets/gamecontrollerdb.txt
  
  if [ -f "${INSTALL}/usr/config/ppsspp-sa/assets/NotoSansJP-Regular.ttf" ]; then
    ln -sf NotoSansJP-Regular.ttf ${INSTALL}/usr/config/ppsspp-sa/assets/Roboto-Condensed.ttf
  fi

  # 8. Cheat DB
  curl -Lo ${INSTALL}/usr/config/ppsspp-sa/PSP/Cheats/cheat.db \
    https://raw.githubusercontent.com/Saramagrean/CWCheat-Database-Plus-/${CHEAT_DB_VERSION}/cheat.db
}
