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
# 🔥 CRIA LAUNCHER COMPATÍVEL COM FAT
if ! ln -sf "$PM_DIR/PortMaster.sh" "$PORTS_SCRIPTS_DIR/PortMaster.sh" 2>/dev/null; then
    cp -f "$PM_DIR/PortMaster.sh" "$PORTS_SCRIPTS_DIR/PortMaster.sh"
fi

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

XML_FILE="/storage/roms/ports_scripts/gamelist.xml"

# Verifica se já existe entrada do PortMaster
if xmlstarlet sel -t -v "count(/gameList/game[name='PortMaster'])" "$XML_FILE" 2>/dev/null | grep -qv '^0$'; then
    echo "PortMaster já existe na gamelist"
else
    echo "Adicionando PortMaster na gamelist"

    # cria arquivo se não existir
    if [ ! -f "$XML_FILE" ]; then
        echo '<?xml version="1.0" encoding="UTF-8"?>' > "$XML_FILE"
        echo '<gameList/>' >> "$XML_FILE"
    else
        # garante estrutura válida
        if ! xmlstarlet sel -t -c "/gameList" "$XML_FILE" >/dev/null 2>&1; then
            echo '<?xml version="1.0" encoding="UTF-8"?>' > "$XML_FILE"
            echo '<gameList/>' >> "$XML_FILE"
        fi
    fi

    # adiciona entrada do PortMaster
    xmlstarlet ed --inplace \
        -s "/gameList" -t elem -n "gameTMP" -v "" \
        -s "/gameList/gameTMP" -t elem -n "path" -v "./PortMaster.sh" \
        -s "/gameList/gameTMP" -t elem -n "name" -v "PortMaster" \
        -s "/gameList/gameTMP" -t elem -n "image" -v "/usr/bin/scripts/setup/setup_images/LaunchPortMaster.png" \
        -s "/gameList/gameTMP" -t elem -n "rating" -v "10" \
        -r "//gameTMP" -v "game" \
        "$XML_FILE"
fi

# 9. Compatibilidade
if [ -f "/usr/bin/portmaster_compatibility.sh" ]; then
    /usr/bin/portmaster_compatibility.sh
fi

# 9.1 Hook: substitui o bgdi (interpretador BennuGD) dos ports pelo do
# sistema. O bgdi do PortMaster é um build SDL2 antigo que renderiza em
# 4:3 dentro do framebuffer Mali. O nosso /usr/bin/bgdi (lib32-bennugd-
# monolithic) é SDL3-native com:
#   - Mali FBDEV fullscreen forçado
#   - SDL_LOGICAL_PRESENTATION_STRETCH (preenche 16:9 nativo)
#   - Audio fix (Mix_OpenAudio bool check)
#   - Funciona via lib32-SDL3 com patch de _TIME_BITS
# Roda toda vez que o launcher do PortMaster é aberto, então ports
# recém-instalados também ficam fullscreen.
replace_bennugd_bgdi() {
    [ -x /usr/bin/bgdi ] || return 0
    local sysmd5
    sysmd5=$(md5sum /usr/bin/bgdi | awk '{print $1}')
    local found=0 replaced=0
    for portbgdi in /storage/roms/ports/*/bgdi; do
        [ -f "$portbgdi" ] || continue
        found=$((found + 1))
        local cmd5
        cmd5=$(md5sum "$portbgdi" | awk '{print $1}')
        if [ "$cmd5" = "$sysmd5" ]; then continue; fi
        # backup primeira vez (preserva original)
        [ -f "${portbgdi}.orig.sdl2" ] || cp -f "$portbgdi" "${portbgdi}.orig.sdl2"
        cp -f /usr/bin/bgdi "$portbgdi"
        chmod +x "$portbgdi"
        replaced=$((replaced + 1))
    done
    [ $found -gt 0 ] && echo "[start_portmaster] bgdi: ${replaced}/${found} bennugd ports atualizados pro SDL3 fullscreen"
}
replace_bennugd_bgdi

# 10. Execução final
@LIBEGL@

cd "$PM_DIR" || exit 1

./PortMaster.sh > /storage/portmaster.log 2>&1

# 10.1 Roda novamente apos PortMaster fechar — pega ports recem-instalados
replace_bennugd_bgdi

sleep 1
systemctl restart emustation 2>/dev/null || systemctl restart emulationstation 2>/dev/null
