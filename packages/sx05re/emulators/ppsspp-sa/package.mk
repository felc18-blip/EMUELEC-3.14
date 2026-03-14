# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="ppsspp-sa"
PKG_REV="1"
PKG_ARCH="aarch64"
PKG_SITE="https://github.com/felc18-blip/ppsspp"
PKG_URL="${PKG_SITE}.git"
PKG_VERSION="3f428cced62fffcc2b9bfa3d204180d08308811c" # v 1.20.1
CHEAT_DB_VERSION="9475ff7b4be805f818f5f40cc3e5116a4a68deac" # Update cheat.db (20/01/2025)
PKG_LICENSE="GPLv2"

# 1. ADIÇÃO CRUCIAL PARA DOWNLOAD DOS SUBMÓDULOS
PKG_GIT_RECURSIVE="yes"

PKG_DEPENDS_TARGET="toolchain ffmpeg libzip SDL2 libpng zlib zip gl4es"
PKG_SHORTDESC="PPSSPPDL"
PKG_LONGDESC="PPSSPP Standalone"
GET_HANDLER_SUPPORT="git"
PKG_BUILD_FLAGS="-lto"

TARGET_CFLAGS+=" -O3 -mcpu=cortex-a53 -ftree-vectorize"
TARGET_CXXFLAGS+=" -O3 -mcpu=cortex-a53 -ftree-vectorize"

PKG_PATCH_DIRS+="${DEVICE}"

# 2. AJUSTE DE FLAGS (FFMPEG e SNAPPY internos para evitar erros de busca no SYSROOT)
PKG_CMAKE_OPTS_TARGET=" -DUSE_SYSTEM_FFMPEG=OFF \
                        -DUSE_SYSTEM_SNAPPY=OFF \
                        -DGLSLANG_USE_LOCAL_DIR=ON \
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
  # Limpeza de ambiente para evitar conflitos de linker
  unset LD
  unset LDFLAGS

  # 3. FORÇA BRUTA PARA SUBMÓDULOS (Garante que ext/ armips e glslang existam)
  cd ${PKG_BUILD}
  git submodule update --init --recursive
  cd -

  # Suas correções originais (DRM e Otimização)
  sed -i 's/\-O[23]//g' ${PKG_BUILD}/CMakeLists.txt
  sed -i "s|include_directories(/usr/include/drm)|include_directories(${SYSROOT_PREFIX}/usr/include/drm)|" ${PKG_BUILD}/CMakeLists.txt

  # Ajustes de caminho para o S905L e redirecionamento para /storage/
  sed -i 's|iniFilename_ = FindConfigFile(useIniFilename ? iniFileName : ppssppIniFilename, \&exists);|iniFilename_ = Path("/storage/.config/ppsspp-sa/PSP/SYSTEM") / ppssppIniFilename;|' ${PKG_BUILD}/Core/Config.cpp
  sed -i 's|std::string filename = StringFromFormat("%s_%d.%s", GenerateFullDiscId(gameFilename).c_str(), slot, extension);|std::string filename = StringFromFormat("%s_%d.%s", gameFilename.WithReplacedExtension("").GetFilename().c_str(), slot, extension);|' ${PKG_BUILD}/Core/SaveState.cpp
  sed -i 's|Path memStickDirectory = g_Config.memStickDirectory;|Path memStickDirectory = Path("/storage/roms/psp/");|' ${PKG_BUILD}/Core/System.cpp
  sed -i 's|Path pspDirectory = memStickDirectory / "PSP";|Path pspDirectory = Path("/storage/.config/ppsspp-sa/PSP/");|' ${PKG_BUILD}/Core/System.cpp
  sed -i 's|const char \*dbPath = "gamecontrollerdb.txt";|const char *dbPath = "/storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt";|' ${PKG_BUILD}/SDL/SDLJoystick.cpp
  sed -i 's|g_VFS.Register("", new DirectoryReader(Path("/usr/local/share/ppsspp/assets")));|g_VFS.Register("", new DirectoryReader(Path("/storage/.config/ppsspp-sa/assets")));|' ${PKG_BUILD}/UI/NativeApp.cpp
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

  if [ -d "${PKG_DIR}/scripts" ]; then
    cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
  fi

  # 4. Busca o binário Standalone (pode estar na raiz ou em build/)
  cp $(find . -name "PPSSPPSDL" -type f | head -1) ${INSTALL}/usr/bin/ppsspp-sa
  chmod 0755 ${INSTALL}/usr/bin/*

  ln -sf /storage/.config/ppsspp-sa/assets ${INSTALL}/usr/bin/assets

  mkdir -p ${INSTALL}/usr/config/ppsspp-sa/PSP/SYSTEM
  mkdir -p ${INSTALL}/usr/config/ppsspp-sa/PSP/Cheats

  # Copia os Assets
  cp -r $(find . -name "assets" -type d | head -1) ${INSTALL}/usr/config/ppsspp-sa/

  if [ -d "${PKG_DIR}/config" ]; then
    cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/ppsspp-sa/
  fi

  if [ -d "${PKG_DIR}/sources/${DEVICE}" ]; then
    cp -rf ${PKG_DIR}/sources/${DEVICE}/* ${INSTALL}/usr/config/ppsspp-sa/PSP/SYSTEM/
  fi

  rm -f ${INSTALL}/usr/config/ppsspp-sa/assets/gamecontrollerdb.txt
  
  # Correção de fontes
  cd ${INSTALL}/usr/config/ppsspp-sa/assets
  ln -sf NotoSansJP-Regular.ttf Roboto-Condensed.ttf
  cd -

  # Download de Cheats
  curl -Lo ${INSTALL}/usr/config/ppsspp-sa/PSP/Cheats/cheat.db https://raw.githubusercontent.com/Saramagrean/CWCheat-Database-Plus-/${CHEAT_DB_VERSION}/cheat.db
}