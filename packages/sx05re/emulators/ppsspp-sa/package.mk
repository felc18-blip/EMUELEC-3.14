# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="ppsspp-sa"
PKG_REV="1"
PKG_ARCH="any"
PKG_SITE="https://github.com/felc18-blip/ppsspp"
PKG_URL="${PKG_SITE}.git"
PKG_VERSION="3f428cced62fffcc2b9bfa3d204180d08308811c" # v 1.20.1
CHEAT_DB_VERSION="9475ff7b4be805f818f5f40cc3e5116a4a68deac" # Update cheat.db (20/01/2025)
PKG_LICENSE="GPLv2"
PKG_DEPENDS_TARGET="toolchain ffmpeg libzip SDL2 libpng zlib zip"
PKG_SHORTDESC="PPSSPPDL"
PKG_LONGDESC="PPSSPP Standalone"
GET_HANDLER_SUPPORT="git"
PKG_BUILD_FLAGS="-lto"

TARGET_CFLAGS+=" -O3 -mcpu=cortex-a53 -ftree-vectorize"
TARGET_CXXFLAGS+=" -O3 -mcpu=cortex-a53 -ftree-vectorize"

### Note:
### This package includes the NotoSansJP-Regular.ttf font.  This font is licensed under
### SIL Open Font License, Version 1.1.  The license can be found in the licenses
### directory in the root of this project, OFL.txt.
###

PKG_PATCH_DIRS+="${DEVICE}"

PKG_CMAKE_OPTS_TARGET=" -DUSE_SYSTEM_FFMPEG=ON \
                        -DUSE_SYSTEM_LIBZIP=ON \
                        -DCMAKE_BUILD_TYPE=Release \
                        -DCMAKE_SYSTEM_NAME=Linux \
                        -DBUILD_SHARED_LIBS=OFF \
                        -DUSE_SYSTEM_LIBPNG=ON \
                        -DANDROID=OFF \
                        -DWIN32=OFF \
                        -DAPPLE=OFF \
                        -DCMAKE_CROSSCOMPILING=ON \
                        -DUSING_QT_UI=OFF \
                        -DUNITTEST=OFF \
                        -DSIMULATOR=OFF \
                        -DHEADLESS=OFF \
                        -DUSE_DISCORD=OFF \
                        -DUSING_GLES2=ON \
                        -DUSING_FBDEV=ON \
						-DARM64=ON \
                        -DUSE_ARM64_DYNAREC=ON \
                        -DVULKAN=OFF"

PKG_CMAKE_OPTS_TARGET+=" -DSDL2=ON"

if [ "${ARCH}" = "aarch64" ]; then
  PKG_CMAKE_OPTS_TARGET+=" -DUSING_GLES2=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DARMV7=ON -DARM_NEON=ON"
fi

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
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
  cp PPSSPPSDL ${INSTALL}/usr/bin/ppsspp-sa
  chmod 0755 ${INSTALL}/usr/bin/*

  # Mudamos o nome do link para evitar conflito com o original
  ln -sf /storage/.config/ppsspp-sa/assets ${INSTALL}/usr/bin/assets-sa

  mkdir -p ${INSTALL}/usr/config/ppsspp-sa/PSP/SYSTEM
  cp -r assets ${INSTALL}/usr/config/ppsspp-sa/
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/ppsspp-sa/

  if [ -d "${PKG_DIR}/sources/${DEVICE}" ]; then
    cp ${PKG_DIR}/sources/${DEVICE}/* ${INSTALL}/usr/config/ppsspp-sa/PSP/SYSTEM
  fi

  rm -f ${INSTALL}/usr/config/ppsspp-sa/assets/gamecontrollerdb.txt
  # Apontando para o NotoSans para economizar RAM (vital para 1GB)
  ln -sf NotoSansJP-Regular.ttf ${INSTALL}/usr/config/ppsspp-sa/assets/Roboto-Condensed.ttf
}
