#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)
# Adaptado para EmuELEC 3.14 / S905L por Felipe

. /etc/profile

# 1. Preparação da pasta de configuração no STORAGE (partição de escrita)
if [ ! -d "/storage/.config/PortMaster" ]; then
    mkdir -p "/storage/.config/PortMaster"
    cp -r "/usr/config/PortMaster/"* "/storage/.config/PortMaster/"
fi

cd /storage/.config/PortMaster

# 2. Atualiza scripts de controle garantindo permissão de execução
cp /usr/config/PortMaster/control.txt control.txt
chmod +x control.txt
cp /usr/config/PortMaster/mapper.txt mapper.txt
chmod +x mapper.txt

# 3. Link do Banco de Dados de Controles (Ajustado para o caminho da foto que você mandou)
rm -f gamecontrollerdb.txt
ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt gamecontrollerdb.txt

# 4. Instalação inicial do PortMaster (se não existir)
if [ ! -d "/storage/roms/ports/PortMaster" ]; then
    mkdir -p /storage/roms/ports
    unzip -o /usr/config/PortMaster/release/PortMaster.zip -d /storage/roms/ports/
    chmod +x /storage/roms/ports/PortMaster/PortMaster.sh
fi

# 5. Limpeza de arquivos desnecessários
[ -f /storage/roms/ports/PortMaster/tasksetter ] && rm -f /storage/roms/ports/PortMaster/tasksetter

# 6. Sincroniza o gptokeyb e os scripts de mapeamento
# No S905L, usamos o gptokeyb que você compilou em /usr/bin/
cp /usr/bin/gptokeyb /storage/roms/ports/PortMaster/gptokeyb
cp /storage/.config/PortMaster/control.txt /storage/roms/ports/PortMaster/control.txt
cp /storage/.config/PortMaster/mapper.txt /storage/roms/ports/PortMaster/mapper.sh
cp /storage/.config/PortMaster/gamecontrollerdb.txt /storage/roms/ports/PortMaster/gamecontrollerdb.txt

# 7. Oculta a pasta PortMaster no Gamelist (Otimizado com xmlstarlet)
# Se você tiver o xmlstarlet instalado como dependência, isso funciona:
if [ -f /storage/roms/ports/gamelist.xml ]; then
    xmlstarlet ed --inplace -d "/gameList/folder[path='./PortMaster']" /storage/roms/ports/gamelist.xml 2>/dev/null
    xmlstarlet ed --inplace --subnode "/gameList" --type elem -n folder -v "" \
        --subnode "/gameList/folder[last()]" --type elem -n path -v "./PortMaster" \
        --subnode "/gameList/folder[last()]" --type elem -n name -v "PortMaster" \
        --subnode "/gameList/folder[last()]" --type elem -n hidden -v "true" /storage/roms/ports/gamelist.xml 2>/dev/null
fi

# 8. Roda o Fixer de Compatibilidade que configuramos antes
if [ -f "/usr/bin/portmaster_compatibility.sh" ]; then
    /usr/bin/portmaster_compatibility.sh
fi

# 9. EXECUÇÃO FINAL
# @LIBEGL@ será substituído pelas variáveis da Mali-450 pelo post_install do package.mk
@LIBEGL@

cd /storage/roms/ports/PortMaster
# Executa o PortMaster jogando os logs para um arquivo para debug se precisar
./PortMaster.sh > /storage/portmaster.log 2>&1