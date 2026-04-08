# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present DiegroSan (https://github.com/Diegrosan)

PKG_NAME="flycast-dojo"
PKG_VERSION="d0e47e572b1e7b355e88bda8308c89d0c5156cbf"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/blueminder/flycast-dojo"
PKG_URL="${PKG_SITE}.git"
# Adicionamos curl e openssl como dependências obrigatórias
PKG_DEPENDS_TARGET="toolchain ${OPENGLES} alsa SDL2 libzip zip asio vksdl curl openssl"
PKG_LONGDESC="Flycast Dojo standalone with Netplay (NextOS Elite Edition)"
PKG_TOOLCHAIN="cmake"
PKG_GIT_CLONE_BRANCH="master"

PKG_CMAKE_OPTS_TARGET+=" -DTHREAD_SANITIZER_AVAILABLE_EXITCODE=1 \
                         -DADDRESS_SANITIZER_AVAILABLE_EXITCODE=1 \
                         -DALL_SANITIZERS_AVAILABLE_EXITCODE=1"

# Bloqueamos o download automático e forçamos o uso das libs do sistema
PKG_CMAKE_OPTS_TARGET+=" -DUSE_GLES=ON -DUSE_VULKAN=OFF -DUSE_HOST_SDL=ON \
                         -DENABLE_CTEST=OFF -DTEST_AUTOMATION=OFF -DASAN=OFF \
                         -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                         -DUSE_SYSTEM_CURL=ON \
                         -DCPR_USE_SYSTEM_CURL=ON \
                         -DBUILD_CURL_FROM_SOURCE=OFF \
                         -DFETCHCONTENT_FULLY_DISCONNECTED=ON"

if [ "${ARCH}" == "arm" ]; then
    PKG_PATCH_DIRS="arm"
fi

post_unpack() {
  # PASSO 1: Criamos a pasta onde o CMake espera encontrar as dependências
  local DEPS_DIR="${PKG_BUILD}/.aarch64-libreelec-linux-gnu/_deps"
  mkdir -p "${DEPS_DIR}"

  # PASSO 2: Baixamos o CPR manualmente usando o Git do seu PC (que tem HTTPS)
  # Isso evita o erro "Protocol https not supported" do CMake
  if [ ! -d "${DEPS_DIR}/cpr-src" ]; then
    echo "Felipe, baixando CPR manualmente para contornar o CMake..."
    git clone --depth 1 https://github.com/libcpr/cpr.git "${DEPS_DIR}/cpr-src"
  fi
}

pre_configure_target() {
  # PASSO 3: Aplicamos a vacina do CMake em TUDO, inclusive no que acabamos de baixar
  find ${PKG_BUILD} -name "CMakeLists.txt" -exec sed -i 's/cmake_minimum_required(VERSION [0-2]\.[0-9][^)]*)/cmake_minimum_required(VERSION 3.5)/gI' {} +

  export CXXFLAGS="${CXXFLAGS} -Wno-error=array-bounds -Wswitch -Wsign-compare -I$(get_install_dir asio)/usr/include"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/config/flycast-dojo

  [ -d "${PKG_DIR}/config" ] && cp -r ${PKG_DIR}/config/* ${INSTALL}/usr/config/flycast-dojo

  # Note: Verifique se o binário realmente está nesta pasta oculta após o build
  if [ -f "${PKG_BUILD}/.aarch64-libreelec-linux-gnu/flycast-dojo" ]; then
      cp "${PKG_BUILD}/.aarch64-libreelec-linux-gnu/flycast-dojo" "${INSTALL}/usr/bin/flycastdojo"
  else
      # Tenta localizar o binário se ele estiver em outro lugar (Ninja build)
      find ${PKG_BUILD} -name "flycast-dojo" -type f -exec cp {} ${INSTALL}/usr/bin/flycastdojo \;
  fi

  if [ -d "${PKG_DIR}/scripts" ]; then
    cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
    [ -f "${INSTALL}/usr/bin/flycastdojo.sh" ] && chmod +x ${INSTALL}/usr/bin/flycastdojo.sh
  fi
}
