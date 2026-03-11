#!/bin/bash

# Carrega o perfil do sistema
. /etc/profile

LOCAL_CONFIG="/storage/.local/share"
CONFIG_DIR="/storage/.config/duckstation"

# Cria as pastas necessárias na partição de escrita
mkdir -p "${LOCAL_CONFIG}"
mkdir -p "${CONFIG_DIR}/database"

# 1. Garante que os arquivos base existam
if [ ! -f "${CONFIG_DIR}/settings.ini" ]; then
    if [ -d "/usr/config/emuelec/configs/duckstation" ]; then
        cp -rf /usr/config/emuelec/configs/duckstation/* "${CONFIG_DIR}/"
    else
        touch "${CONFIG_DIR}/settings.ini"
    fi
fi

# 2. Gerenciamento de Texturas (Corrigido para não dar erro se não existir)
if [ ! -L "${CONFIG_DIR}/textures" ]; then
    [ -d "${CONFIG_DIR}/textures" ] && rm -rf "${CONFIG_DIR}/textures"
    mkdir -p /storage/roms/psx/textures
    ln -sf /storage/roms/psx/textures "${CONFIG_DIR}/textures"
fi

# 3. Link para a pasta local
if [ ! -L "${LOCAL_CONFIG}/duckstation" ]; then
    rm -rf "${LOCAL_CONFIG}/duckstation"
    ln -sf "${CONFIG_DIR}" "${LOCAL_CONFIG}/duckstation"
fi

# 4. Execução (Simplificada para evitar erros de arquivo não encontrado)
if [[ "${1}" == *"duckstation_gui.pbp"* ]]; then
    duckstation-nogui -batch -nogui
else
    # Removi o > /dev/null para que você consiga ver erros no log se ele fechar
    duckstation-nogui -batch -nogui -settings "${CONFIG_DIR}/settings.ini" -- "${1}"
fi