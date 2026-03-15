# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert

PKG_NAME="duckstation-sa"
PKG_LICENSE="GPLv3"
# Adicionado libmali e tirado pulseaudio se não for necessário, mantendo compatibilidade EmuELEC
PKG_DEPENDS_TARGET="toolchain SDL2 nasm:host openssl libidn2 nghttp2 zlib curl libevdev ecm zstd libwebp libmali"
PKG_SITE="https://github.com/stenzek/duckstation"
PKG_URL="${PKG_SITE}.git"
PKG_SHORTDESC="Fast PlayStation 1 emulator for AArch64 (EmuELEC Standalone)"
PKG_TOOLCHAIN="cmake"

# Usando o commit do JELOS que é mais estável para standalone
PKG_VERSION="bfa792ddbff11c102521124f235ccb310cac6e6a"

pre_configure_target() {
    # Logica de GLES/Mali específica do EmuELEC para Amlogic-old
    if [ "${DEVICE}" == "Amlogic-old" ]; then
        # ADICIONADO: -DUSE_WAYLAND=OFF para evitar o erro de detecção
        EXTRA_OPTS="-DUSE_DRMKMS=OFF -DUSE_FBDEV=ON -DUSE_MALI=ON -DUSE_GLES2=ON -DGLAD_GLES2=ON -DUSE_WAYLAND=OFF"
        # Fix para kernel 3.14 (input)
        cp -rf $(get_build_dir libevdev)/include/linux/linux/input-event-codes.h ${SYSROOT_PREFIX}/usr/include/linux/
    else
        EXTRA_OPTS="-DUSE_DRMKMS=ON -DENABLE_EGL=ON -DUSE_WAYLAND=OFF"
    fi

    # ... restante das flags de otimização ...
PKG_CMAKE_OPTS_TARGET+=" -DANDROID=OFF \
                         -DENABLE_DISCORD_PRESENCE=OFF \
                         -DBUILD_QT_FRONTEND=OFF \
                         -DBUILD_NOGUI_FRONTEND=ON \
                         -DCMAKE_BUILD_TYPE=Release \
                         -DBUILD_SHARED_LIBS=OFF \
                         -DUSE_SDL2=ON \
                         -DENABLE_CHEEVOS=ON \
                         -DUSE_EVDEV=ON \
                         -DUSE_X11=OFF \
                         -DUSE_WAYLAND=OFF \
                         -DENABLE_VULKAN=OFF \
                         -DCMAKE_SKIP_RPATH=ON \
                         -DCMAKE_BUILD_WITH_INSTALL_RPATH=OFF \
                         -DCMAKE_INSTALL_RPATH= \
                         -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE \
                         ${EXTRA_OPTS}"
}

pre_make_target() {
    # --- CORREÇÕES DE CÓDIGO ---
    
    # 1. Correção de offsetof (Caminho corrigido para a versão bfa792d)
    CPU_GEN_FILE="${PKG_BUILD}/src/core/cpu_recompiler_code_generator.cpp"
    if [ -f "${CPU_GEN_FILE}" ]; then
        sed -i 's/offsetof(State, gte_regs.r32\[index\])/offsetof(State, gte_regs.r32) + (sizeof(u32) * index)/g' "${CPU_GEN_FILE}"
    fi
    
    # 2. Adição de includes (Procurando o arquivo correto se ele mudou de lugar)
    # Nesta versão, o arquivo pode estar em src/duckstation-nogui ou src/common
    GAME_SETTINGS="${PKG_BUILD}/src/frontend-common/game_settings.cpp"
    if [ -f "${GAME_SETTINGS}" ]; then
        sed -i '1i #include <algorithm>\n#include <cstdio>\n#include <stdint.h>' "${GAME_SETTINGS}"
    else
        echo "Aviso: game_settings.cpp não encontrado no caminho padrão, pulando patch de include..."
    fi
    
    # 3. Limpeza de lixo do Windows
    rm -rf ${PKG_BUILD}/dep/msvc/qt
}

makeinstall_target() {
    mkdir -p ${INSTALL}/usr/bin
    mkdir -p ${INSTALL}/usr/config/duckstation/database

    # Copia o binário compilado (o JELOS usa pasta oculta .aarch64...)
    if [ -f "${PKG_BUILD}/.aarch64-libreelec-linux-gnu/bin/duckstation-nogui" ]; then
        cp -rf ${PKG_BUILD}/.aarch64-libreelec-linux-gnu/bin/duckstation-nogui ${INSTALL}/usr/bin/
    else
        cp -rf ${PKG_BUILD}/bin/duckstation-nogui ${INSTALL}/usr/bin/
    fi

    # Scripts de inicialização
    if [ -d "${PKG_DIR}/scripts" ]; then
        cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
        chmod +x ${INSTALL}/usr/bin/*.sh
    fi

    # Dados e Banco de Dados (Resources)
    cp -rf ${PKG_BUILD}/data/* ${INSTALL}/usr/config/duckstation/
}

post_install() {
    # Ajusta o script para procurar a pasta correta de recursos
    RESOURCE_FOLDER="database"
    if [ -f "${INSTALL}/usr/bin/start_duckstation.sh" ]; then
        sed -e "s/@RESOURCE_FOLDER@/${RESOURCE_FOLDER}/g" \
            -i ${INSTALL}/usr/bin/start_duckstation.sh
    fi
}