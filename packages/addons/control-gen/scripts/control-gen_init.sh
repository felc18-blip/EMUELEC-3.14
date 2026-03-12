#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

# 1. Ajustado para o caminho real que vimos na sua Captura de Tela
GPTK_DIR="/storage/.config/emuelec/configs/gptokeyb"

if [ ! -d "$GPTK_DIR" ]; then
    mkdir -p "$GPTK_DIR"
fi

# 2. Link gamecontrollerdb.txt 
# Usando o caminho da Box onde o banco de dados realmente fica
ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt "$GPTK_DIR/gamecontrollerdb.txt"

# 3. Link gptokeyb
# Faz o link do binário para a pasta de config (alguns scripts antigos buscam aqui)
ln -sf /usr/bin/gptokeyb "$GPTK_DIR/gptokeyb"

# 4. Run control-gen
# Gera o mapeamento inicial baseado no seu es_input.cfg
# Salvando na pasta correta para o EmuELEC reconhecer
/usr/bin/control-gen > "$GPTK_DIR/control.ini"

# Garante que as permissões estejam corretas na partição de escrita
chmod 0755 "$GPTK_DIR"/*