################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#      Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
################################################################################

PKG_NAME="ppssppsa"
PKG_VERSION="afbc66a318b86432642b532c575241f3716642ef"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/hrydgard/ppsspp"
PKG_URL="https://github.com/hrydgard/ppsspp.git"
PKG_DEPENDS_TARGET="toolchain SDL2 libzip zstd"
PKG_LONGDESC="A PSP emulator for Android, Windows, Mac, Linux and Blackberry 10, written in C++."
GET_HANDLER_SUPPORT="git"


post_unpack() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive --force
}

pre_configure_target() {
  # O CMake sempre gera o arquivo com este nome padrão
  PKG_LIBPATH="lib/ppsspp_libretro.so"
  
  # Este é o nome que queremos que ele tenha no sistema final
  FINAL_LIB_NAME="ppssppsa_libretro.so"

  if [ ! "${OPENGL}" = "no" ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd glew glslang"
    PKG_CMAKE_OPTS_TARGET+=" -DUSING_FBDEV=OFF \
                             -DUSING_GLES2=OFF"
  fi

  if [ "${OPENGLES_SUPPORT}" = yes ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGLES}"
    PKG_CMAKE_OPTS_TARGET+=" -DUSING_FBDEV=ON \
                             -DUSING_EGL=OFF \
                             -DUSING_GLES2=ON \
                             -DVULKAN=OFF \
                             -DUSE_VULKAN_DISPLAY_KHR=OFF \
                             -DUSING_X11_VULKAN=OFF"
  fi

  if [ "${VULKAN_SUPPORT}" = "yes" ]
  then
    PKG_DEPENDS_TARGET+=" vulkan-loader vulkan-headers"
    PKG_CMAKE_OPTS_TARGET+=" -DUSE_VULKAN_DISPLAY_KHR=ON \
                             -DVULKAN=ON \
                             -DEGL_NO_X11=1 \
                             -DMESA_EGL_NO_X11_HEADERS=1"
  else
    PKG_CMAKE_OPTS_TARGET+=" -DVULKAN=OFF"
  fi

  if [ "${DISPLAYSERVER}" = "wl" ]; then
    PKG_DEPENDS_TARGET+=" wayland ${WINDOWMANAGER}"
    PKG_CMAKE_OPTS_TARGET+=" -DUSE_WAYLAND_WSI=ON"
  else
    PKG_CMAKE_OPTS_TARGET+=" -DUSE_WAYLAND_WSI=OFF"
  fi

  case ${TARGET_ARCH} in
    aarch64)
      PKG_CMAKE_OPTS_TARGET+=" -DFORCED_CPU=aarch64"
    ;;
  esac

  PKG_CMAKE_OPTS_TARGET+=" -DUSE_SYSTEM_FFMPEG=OFF \
                           -DCMAKE_BUILD_TYPE=Release \
                           -DCMAKE_SYSTEM_NAME=Linux \
                           -DBUILD_SHARED_LIBS=OFF \
                           -DANDROID=OFF \
                           -DWIN32=OFF \
                           -DAPPLE=OFF \
                           -DLIBRETRO=ON \
                           -DCMAKE_CROSSCOMPILING=ON \
                           -DUSING_QT_UI=OFF \
                           -DUNITTEST=OFF \
                           -DSIMULATOR=OFF \
                           -DHEADLESS=OFF \
                           -DUSE_DISCORD=OFF"
}

pre_make_target() {
  if [ "${TARGET_ARCH}" = "aarch64" ]; then
    sed -i "s|aarch64-linux-gnu-|${TARGET_PREFIX}|g" ${PKG_BUILD}/ffmpeg/linux_arm64.sh
    (cd ${PKG_BUILD}/ffmpeg && ./linux_arm64.sh)
  fi

  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  # Copiamos o .so original renomeando para o nome SA desejado
  cp ${PKG_LIBPATH} ${INSTALL}/usr/lib/libretro/ppssppsa_libretro.so
}