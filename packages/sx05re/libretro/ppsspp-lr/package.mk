################################################################################
# PPSSPP-LR: Versão "Força Bruta" para Submódulos
################################################################################

PKG_TOOLCHAIN="cmake"
PKG_NAME="ppsspp-lr"
PKG_VERSION="56b3c8674265a0203cf3276a4b410a264abe6766"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/hrydgard/ppsspp"
PKG_URL="https://github.com/hrydgard/ppsspp.git"

# Tentamos manter o automático
PKG_GIT_RECURSIVE="yes" 

PKG_DEPENDS_TARGET="toolchain SDL2 ffmpeg libzip zstd gl4es"

pre_configure_target() {
  PKG_LIBNAME="ppsspp_libretro.so"
  PKG_LIBPATH="lib/${PKG_LIBNAME}"

  # --- FORÇA BRUTA ---
  # Se as pastas estiverem vazias, o comando abaixo vai baixar tudo na marra
  echo "Garantindo submódulos (armips, glslang, etc)..."
  cd ${PKG_BUILD}
  git submodule update --init --recursive
  cd -
  # -------------------

  unset LD
  unset LDFLAGS

  # Flags para GLES2 (Mali-450)
  if [ "${OPENGLES_SUPPORT}" = yes ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DUSING_FBDEV=ON \
                             -DUSING_EGL=ON \
                             -DUSING_GLES2=ON \
                             -DGLES3=OFF \
                             -DVULKAN=OFF"
  fi

  case ${TARGET_ARCH} in
    aarch64)
      PKG_CMAKE_OPTS_TARGET+=" -DFORCED_CPU=aarch64"
    ;;
  esac

  # Aqui resolvemos o erro do FFmpeg e Snappy
  # Usamos o FFmpeg INTERNO (-DUSE_SYSTEM_FFMPEG=OFF) porque o CMake não achou o do sistema
  PKG_CMAKE_OPTS_TARGET+=" \
                          -DUSE_SYSTEM_FFMPEG=OFF \
                          -DUSE_SYSTEM_SNAPPY=OFF \
                          -DGLSLANG_USE_LOCAL_DIR=ON \
                          -DCMAKE_BUILD_TYPE=Release \
                          -DCMAKE_SYSTEM_NAME=Linux \
                          -DBUILD_SHARED_LIBS=OFF \
                          -DLIBRETRO=ON \
                          -DCMAKE_CROSSCOMPILING=ON \
                          -DUNITTEST=OFF \
                          -DUSE_DISCORD=OFF"
}

pre_make_target() {
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro

  # Vamos procurar o arquivo na pasta de build e copiar para o destino
  # O find garante que ele ache, esteja em lib/ ou na raiz
  find ${PKG_BUILD} -name "ppsspp_libretro.so" -exec cp {} ${INSTALL}/usr/lib/libretro/ppsspp_lr_libretro.so \;
  
  echo "Arquivo copiado com sucesso para ${INSTALL}/usr/lib/libretro/ppsspp_lr_libretro.so"
}