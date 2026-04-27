#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS-Elite-Edition: PortMaster installer/refresher
#
# Reinstala (ou atualiza) PortMaster a partir do ZIP local que o pacote
# `addons/portmaster` empacota em /usr/config/PortMaster/release/PortMaster.zip.
# Diferente do install_portmaster.sh original do EmuELEC (que baixa do
# GitHub em runtime), aqui usamos o bundle local — funciona offline e já
# vem com a versão validada para Amlogic-old.
#
# Após extrair, aplica os patches NextOS (alias hardware.py + platform.py
# + .CUSTOM_DEVICE) chamando o nosso /usr/bin/start_portmaster.sh, que é
# idempotente — rodar de novo sobre uma instalação já patcheada é no-op.
#
# Disparado a partir do menu Setup do EmulationStation (entry "Install
# PortMaster" / equivalente).

. /etc/profile

ZIP="/usr/config/PortMaster/release/PortMaster.zip"
PORTS_DIR="/storage/roms/ports"
PORTS_SCRIPTS_DIR="/storage/roms/ports_scripts"
PM_DIR="$PORTS_DIR/PortMaster"
XML_FILE="$PORTS_SCRIPTS_DIR/gamelist.xml"

confirm() {
    text_viewer -y -w -t "Install PortMaster" -f 24 -m \
        "Reinstala/atualiza PortMaster a partir do bundle local NextOS\n\nIsso vai:\n  - Apagar /storage/roms/ports/PortMaster/\n  - Extrair PortMaster.zip novo\n  - Reaplicar patches NextOS (alias EmuELEC)\n  - Adicionar entry na gamelist.xml\n\nContinuar?"
    [[ $? == 21 ]]
}

do_install() {
    ee_console enable

    echo "[install_portmaster] sanity checks…"
    if [ ! -f "$ZIP" ]; then
        echo "ERROR: ZIP não encontrado em $ZIP — pacote portmaster não instalado?"
        ee_console disable
        return 1
    fi

    mkdir -p "$PORTS_DIR" "$PORTS_SCRIPTS_DIR"

    echo "[install_portmaster] removendo instalação anterior…"
    rm -rf "$PM_DIR"

    echo "[install_portmaster] extraindo bundle local…"
    unzip -o "$ZIP" -d "$PORTS_DIR" || {
        echo "ERROR: unzip falhou"
        ee_console disable
        return 1
    }
    chmod +x "$PM_DIR/PortMaster.sh"

    echo "[install_portmaster] aplicando patches NextOS via start_portmaster.sh…"
    # /usr/bin/start_portmaster.sh é idempotente: detecta se patches já estão
    # presentes e não duplica. Aqui rodamos só a fase de patch (skip exec).
    # Truque: chama o trecho Python in-line para re-patchar deterministicamente
    # mesmo se start_portmaster.sh evoluir.
    HW_PY="$PM_DIR/pylibs/harbourmaster/hardware.py"
    PL_PY="$PM_DIR/pylibs/harbourmaster/platform.py"
    if [ -f "$HW_PY" ] && ! grep -q "NextOS-Elite-Edition is an EmuELEC fork" "$HW_PY"; then
        python3 - "$HW_PY" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
needle = "info.setdefault('name', 'Unknown')"
add = ("    # NextOS-Elite-Edition is an EmuELEC fork — alias name so PortMaster\n"
       "    # picks PlatformEmuELEC (gamelist_add, GCD_PortMaster, etc.).\n"
       "    if info.get('name', '').lower().startswith('nextos'):\n"
       "        info['name'] = 'EmuELEC'\n"
       "\n    ")
if needle in s:
    open(p, 'w').write(s.replace(needle, add + needle))
    print("hardware.py patched")
PY
    fi
    if [ -f "$PL_PY" ] && ! grep -q "NextOS-Elite-Edition fork" "$PL_PY"; then
        sed -i "s|'emuelec':   PlatformEmuELEC,|'emuelec':   PlatformEmuELEC,\n    'nextos':    PlatformEmuELEC,  # NextOS-Elite-Edition fork|" "$PL_PY"
        echo "platform.py patched"
    fi
    rm -rf "$PM_DIR/pylibs/harbourmaster/__pycache__" 2>/dev/null

    mkdir -p /storage/.config
    [ -f /storage/.config/.CUSTOM_DEVICE ] || echo "Amlogic-old" > /storage/.config/.CUSTOM_DEVICE

    echo "[install_portmaster] criando launcher symlink/copia em ports_scripts…"
    if ! ln -sf "$PM_DIR/PortMaster.sh" "$PORTS_SCRIPTS_DIR/PortMaster.sh" 2>/dev/null; then
        cp -f "$PM_DIR/PortMaster.sh" "$PORTS_SCRIPTS_DIR/PortMaster.sh"
    fi
    chmod +x "$PORTS_SCRIPTS_DIR/PortMaster.sh"

    echo "[install_portmaster] adicionando entry na gamelist.xml…"
    if [ ! -f "$XML_FILE" ]; then
        echo '<?xml version="1.0" encoding="UTF-8"?>' > "$XML_FILE"
        echo '<gameList/>' >> "$XML_FILE"
    fi

    if xmlstarlet sel -t -v "count(/gameList/game[name='PortMaster'])" "$XML_FILE" 2>/dev/null | grep -qv '^0$'; then
        echo "[install_portmaster] PortMaster já está em ${XML_FILE}"
    else
        xmlstarlet ed --inplace \
            -s "/gameList" -t elem -n "gameTMP" -v "" \
            -s "/gameList/gameTMP" -t elem -n "path" -v "./PortMaster.sh" \
            -s "/gameList/gameTMP" -t elem -n "name" -v "PortMaster" \
            -s "/gameList/gameTMP" -t elem -n "desc" -v "Browse and install ports — game source ports curated for handheld retro Linux distros. Built-in to NextOS-Elite-Edition." \
            -s "/gameList/gameTMP" -t elem -n "developer" -v "PortsMaster Team" \
            -s "/gameList/gameTMP" -t elem -n "publisher" -v "NextOS-Elite-Edition" \
            -s "/gameList/gameTMP" -t elem -n "genre" -v "Launcher" \
            -s "/gameList/gameTMP" -t elem -n "image" -v "/usr/bin/scripts/setup/setup_images/LaunchPortMaster.png" \
            -s "/gameList/gameTMP" -t elem -n "rating" -v "10" \
            -r "//gameTMP" -v "game" \
            "$XML_FILE"
    fi

    echo "[install_portmaster] done."
    ee_console disable
    rm -f /tmp/display 2>/dev/null
    return 0
}

if confirm; then
    if do_install; then
        text_viewer -y -w -t "Install PortMaster Complete" -f 24 -m \
            "PortMaster instalado/atualizado com patches NextOS.\n\nReiniciar o EmulationStation agora?"
        if [[ $? == 21 ]]; then
            systemctl restart emustation 2>/dev/null || systemctl restart emulationstation 2>/dev/null
        fi
    else
        text_viewer -e -w -t "Install PortMaster FAILED" -f 24 -m \
            "Algo deu errado. Veja o terminal para detalhes."
    fi
fi
