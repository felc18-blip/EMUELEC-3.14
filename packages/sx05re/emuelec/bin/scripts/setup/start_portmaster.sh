#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS
# Adaptado para EmuELEC 3.14 / S905L por Felipe

. /etc/profile

CONFIG_DIR="/storage/.config/PortMaster"
PORTS_DIR="/storage/roms/ports"
PORTS_SCRIPTS_DIR="/storage/roms/ports_scripts"
PM_DIR="$PORTS_DIR/PortMaster"

# gerar control.ini automaticamente
control-gen > /storage/.config/emuelec/configs/gptokeyb/control.ini

# 1. Preparação da pasta de configuração no STORAGE
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    cp -r /usr/config/PortMaster/* "$CONFIG_DIR/"
fi


cd "$CONFIG_DIR" || exit 1

# 2. Atualiza scripts de controle
cp -f /usr/config/PortMaster/control.txt control.txt
chmod +x control.txt

cp -f /usr/config/PortMaster/mapper.txt mapper.txt
chmod +x mapper.txt

# 3. Link do banco de controles SDL
rm -f gamecontrollerdb.txt

if [ -f /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt ]; then
    ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt gamecontrollerdb.txt
else
    ln -sf /usr/config/SDL-GameControllerDB/gamecontrollerdb.txt gamecontrollerdb.txt
fi

# 4. Garantir estrutura de diretórios
mkdir -p "$PORTS_DIR"
mkdir -p "$PORTS_SCRIPTS_DIR"

# garantir permissões corretas
chmod 775 "$PORTS_DIR"
chmod 775 "$PORTS_SCRIPTS_DIR"

# 5. Instalação inicial do PortMaster
if [ ! -f "$PM_DIR/PortMaster.sh" ]; then
    rm -rf "$PM_DIR"
    unzip -o /usr/config/PortMaster/release/PortMaster.zip -d "$PORTS_DIR" || exit 1
    chmod +x "$PM_DIR/PortMaster.sh"
fi

# 🔥 CRIA LAUNCHER NO PORTS_SCRIPTS
ln -sf "$PM_DIR/PortMaster.sh" "$PORTS_SCRIPTS_DIR/PortMaster.sh"
chmod +x "$PORTS_SCRIPTS_DIR/PortMaster.sh"

# 6. Limpeza de arquivos desnecessários
[ -f "$PM_DIR/tasksetter" ] && rm -f "$PM_DIR/tasksetter"

# 7. Sincroniza gptokeyb e arquivos de controle
cp -f /usr/bin/gptokeyb "$PM_DIR/gptokeyb"
chmod +x "$PM_DIR/gptokeyb"

cp -f "$CONFIG_DIR/control.txt" "$PM_DIR/control.txt"
cp -f "$CONFIG_DIR/mapper.txt" "$PM_DIR/mapper.txt"
chmod +x "$PM_DIR/mapper.txt"

cp -f "$CONFIG_DIR/gamecontrollerdb.txt" "$PM_DIR/gamecontrollerdb.txt"

# 8. Oculta pasta PortMaster no gamelist
if [ -f "$PORTS_DIR/gamelist.xml" ]; then
    xmlstarlet ed --inplace -d "/gameList/folder[path='./PortMaster']" "$PORTS_DIR/gamelist.xml" 2>/dev/null
    xmlstarlet ed --inplace \
        --subnode "/gameList" --type elem -n folder -v "" \
        --subnode "/gameList/folder[last()]" --type elem -n path -v "./PortMaster" \
        --subnode "/gameList/folder[last()]" --type elem -n name -v "PortMaster" \
        --subnode "/gameList/folder[last()]" --type elem -n hidden -v "true" \
        "$PORTS_DIR/gamelist.xml" 2>/dev/null
fi

# 9. Compatibilidade
if [ -f "/usr/bin/portmaster_compatibility.sh" ]; then
    /usr/bin/portmaster_compatibility.sh
fi

# 10. Execução final
@LIBEGL@

cd "$PM_DIR" || exit 1

./PortMaster.sh > /storage/portmaster.log 2>&1

sleep 1
systemctl restart emustation 2>/dev/null || systemctl restart emulationstation 2>/dev/null
