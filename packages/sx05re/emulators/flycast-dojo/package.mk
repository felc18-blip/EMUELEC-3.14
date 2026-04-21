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
  local DEPS_DIR="${PKG_BUILD}/.aarch64-libreelec-linux-gnu/_deps"
  mkdir -p "${DEPS_DIR}"

  # Configura o git para não pedir senha
  export GIT_TERMINAL_PROMPT=0

  # Downloads manuais necessários
  [ ! -d "${DEPS_DIR}/cpr-src" ] && git clone --depth 1 https://github.com/libcpr/cpr.git "${DEPS_DIR}/cpr-src"
  [ ! -f "${PKG_BUILD}/core/deps/libchdr/CMakeLists.txt" ] && git clone --depth 1 https://github.com/rtissera/libchdr.git "${PKG_BUILD}/core/deps/libchdr"

  # --- LIMPEZA DO BREAKPAD ---
  echo "Felipe, removendo o Breakpad da linkagem final..."

  # 1. Desativa no CMake
  sed -i 's/set(USE_BREAKPAD ON)/set(USE_BREAKPAD OFF)/g' "${PKG_BUILD}/CMakeLists.txt"
  sed -i 's/add_subdirectory(core\/deps\/breakpad)/# desativado/g' "${PKG_BUILD}/CMakeLists.txt"

  # 2. REMOVE A LIB DA LINKAGEM (Evita o erro -lbreakpad_client)
  sed -i 's/breakpad_client//g' "${PKG_BUILD}/CMakeLists.txt"

  # 3. Neutraliza o código no main.cpp
  sed -i '40i #undef USE_BREAKPAD' "${PKG_BUILD}/core/linux-dist/main.cpp"
}

pre_configure_target() {
  # 1. Vacina de versão do CMake
  find ${PKG_BUILD} -name "CMakeLists.txt" -exec sed -i 's/cmake_minimum_required(VERSION [0-2]\.[0-9][^)]*)/cmake_minimum_required(VERSION 3.5)/gI' {} +

  # 2. LIMPEZA FÍSICA DO BREAKPAD NO CÓDIGO (A Marretada)
  # Deleta a linha 45 do main.cpp onde está o include que trava tudo
  if [ -f "${PKG_BUILD}/core/linux-dist/main.cpp" ]; then
    echo "Felipe, removendo fisicamente a linha do Breakpad..."
    sed -i 's/#include "breakpad\/client\/linux\/handler\/exception_handler.h"/\/\/ removido/g' "${PKG_BUILD}/core/linux-dist/main.cpp"
    # Adicionamos uma trava de segurança no topo do arquivo
    sed -i '1i #undef USE_BREAKPAD' "${PKG_BUILD}/core/linux-dist/main.cpp"
  fi

  # 3. Limpeza das definições do CMake para o Ninja não se confundir
  find ${PKG_BUILD} -name "CMakeLists.txt" -exec sed -i 's/USE_BREAKPAD//g' {} +
  sed -i 's/set(USE_BREAKPAD ON)/set(USE_BREAKPAD OFF)/g' "${PKG_BUILD}/CMakeLists.txt"

  # 4. Flags de compilação para o GCC 15
  export CXXFLAGS="${CXXFLAGS} -Wno-error=array-bounds -Wno-error=deprecated-declarations -Wno-error=unused-result -Wno-sign-compare -DUSE_BREAKPAD=0 -DCP_NO_BREAKPAD"
  export CXXFLAGS="${CXXFLAGS} -I$(get_install_dir asio)/usr/include"

  # Linkagem limpa
  export LDFLAGS="${LDFLAGS} -lcurl -lssl -lcrypto"
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
