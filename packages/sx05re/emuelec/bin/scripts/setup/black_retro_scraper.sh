#!/bin/bash
export TERM=linux

###############################################################################
# BLACK RETRO ELITE - SCRAPER MANAGER (STABLE)
###############################################################################

ES_SYSTEMS="/usr/config/emulationstation/es_systems.cfg"
ES_SETTINGS="/storage/.config/emulationstation/es_settings.cfg"

# IMPORTANTE: NÃO limpar /storage/.skyscraper/cache/ automaticamente.
# O cache é a fonte de verdade do Skyscraper pra regenerar gamelist.xml
# quando você scrapa games novos. Se apaga o cache entre sessões, a
# próxima geração de gamelist substitui o arquivo inteiro com só os games
# do novo scrape (perde todos os anteriores). Pra limpar manualmente, use
# o item 3 "Limpar cache TOTAL Skyscraper" do menu principal.
# Setup Skyscraper: garante que /storage/.config/skyscraper/ tenha os configs
# (artwork.xml e config.ini) — popula a partir de /usr/config/skyscraper/ em
# imagens novas onde o /storage ainda está limpo. Depois cria symlinks pra
# /storage/.skyscraper/ (onde Skyscraper efetivamente procura, pois HOME=/storage).
mkdir -p /storage/.config/skyscraper /storage/.skyscraper
for f in artwork.xml config.ini; do
    # Popula /storage/.config se estiver faltando
    if [ ! -f "/storage/.config/skyscraper/$f" ] && [ -f "/usr/config/skyscraper/$f" ]; then
        cp "/usr/config/skyscraper/$f" "/storage/.config/skyscraper/$f"
    fi
    # Symlink em /storage/.skyscraper se ainda não houver
    if [ ! -e "/storage/.skyscraper/$f" ] && [ -f "/storage/.config/skyscraper/$f" ]; then
        ln -sf "/storage/.config/skyscraper/$f" "/storage/.skyscraper/$f"
    fi
done

DEV_ID="xxx"
DEV_PASS="xxx"
SOFTNAME="BlackRetroElite"

###############################################################################
# CONFIGURACOES DO SCRAPER
###############################################################################

SCRAPER_VIDEO="off"
SCRAPER_SCREENSHOT="on"
SCRAPER_BOXART="on"
SCRAPER_WHEEL="off"

###############################################################################
# UI
###############################################################################

msg() {
dialog --title "BLACK RETRO ELITE - SCRAPER" --msgbox "$1" 15 60
}

get_rom_systems() {

find /storage/roms -mindepth 1 -maxdepth 1 -type d
}

###############################################################################
# VALIDAR ARQUIVOS
###############################################################################

validate_files() {

if [ ! -f "$ES_SYSTEMS" ]; then
    msg "Erro: es_systems.cfg nao encontrado."
    exit 1
fi

if [ ! -f "$ES_SETTINGS" ]; then
    msg "Erro: es_settings.cfg nao encontrado."
    exit 1
fi
}

scraper_settings_menu() {

while true; do

STATUS_VIDEO=$([ "$SCRAPER_VIDEO" = "on" ] && echo "ON" || echo "OFF")
STATUS_SCREEN=$([ "$SCRAPER_SCREENSHOT" = "on" ] && echo "ON" || echo "OFF")
STATUS_BOX=$([ "$SCRAPER_BOXART" = "on" ] && echo "ON" || echo "OFF")
STATUS_WHEEL=$([ "$SCRAPER_WHEEL" = "on" ] && echo "ON" || echo "OFF")

CHOICE=$(dialog --menu "Configuracoes do Scraper" 20 60 10 \
1 "Video: $STATUS_VIDEO" \
2 "Screenshot: $STATUS_SCREEN" \
3 "Boxart: $STATUS_BOX" \
4 "Wheel: $STATUS_WHEEL" \
5 "Regiao: $SCRAPER_REGION" \
6 "Idioma: $SCRAPER_LANG" \
0 "Voltar" \
2>&1 >/dev/tty)

case "$CHOICE" in
1)
    [ "$SCRAPER_VIDEO" = "on" ] && SCRAPER_VIDEO="off" || SCRAPER_VIDEO="on"
;;
2)
    [ "$SCRAPER_SCREENSHOT" = "on" ] && SCRAPER_SCREENSHOT="off" || SCRAPER_SCREENSHOT="on"
;;
3)
    [ "$SCRAPER_BOXART" = "on" ] && SCRAPER_BOXART="off" || SCRAPER_BOXART="on"
;;
4)
    [ "$SCRAPER_WHEEL" = "on" ] && SCRAPER_WHEEL="off" || SCRAPER_WHEEL="on"
;;
5)
    NEW_REGION=$(dialog --inputbox "Digite a regiao (ex: br, us, eu, jp)" 8 40 "$SCRAPER_REGION" 2>&1 >/dev/tty)
    [ -n "$NEW_REGION" ] && SCRAPER_REGION="$NEW_REGION"
;;
6)
    NEW_LANG=$(dialog --inputbox "Digite o idioma (ex: pt, en, es)" 8 40 "$SCRAPER_LANG" 2>&1 >/dev/tty)
    [ -n "$NEW_LANG" ] && SCRAPER_LANG="$NEW_LANG"
;;
0|"")
    return
;;
esac

done
}

###############################################################################
# TECLADO VIRTUAL
###############################################################################

virtual_keyboard() {
    TEXT="${1:-}"
    CAPS=1   # 1 = MAIÚSCULO | 0 = minúsculo

    while true; do
        CAPS_LABEL="Caps: ON"
        [ "$CAPS" -eq 0 ] && CAPS_LABEL="Caps: off"

        KEY=$(dialog --cancel-label "Voltar" --menu "\
TECLADO VIRTUAL  [$CAPS_LABEL]

 0  1  2  3  4   5  6  7  8  9 --- USE R1 PRA IR MAIS RAPIDO ENTRE AS LETRAS
 A  B  C  D  E   F  G  H  I  J --- USE R2 PRA CHEGAR AO FIM DO TECLADO ----
 K  L  M  N  O   P  Q  R  S  T --- X SELECIONAR LETRAS AO DIGITAR CLIQUE --
 U  V  W  X  Y   Z ----------- EM CONFIRMAR PARA SALVAR --------------------

Texto: [$TEXT]
" 26 76 42 \
            0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" \
            A "A" B "B" C "C" D "D" E "E" F "F" G "G" H "H" I "I" J "J" \
            K "K" L "L" M "M" N "N" O "O" P "P" Q "Q" R "R" S "S" T "T" \
            U "U" V "V" W "W" X "X" Y "Y" Z "Z" \
            CAPS "Caps Lock" SP "Espaco" BS "Apagar" OK "Confirmar" EXIT "Sair" \
            2>&1 >/dev/tty)

        RET=$?
        [ $RET -ne 0 ] && return 1   # ESC / Cancelar

        case "$KEY" in
            A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z)
                if [ "$CAPS" -eq 1 ]; then
                    TEXT+="$KEY"
                else
                    TEXT+="$(printf "%s" "$KEY" | tr A-Z a-z)"
                fi
                ;;
            0|1|2|3|4|5|6|7|8|9)
                TEXT+="$KEY"
                ;;
            CAPS)
                CAPS=$((1-CAPS))
                ;;
            SP)
                TEXT+=" "
                ;;
            BS)
                TEXT="${TEXT%?}"
                ;;
            OK)
                echo "$TEXT"
                return 0
                ;;
            EXIT)
                return 1
                ;;
        esac
    done
}

# Retorna texto via método selecionado pelo user (virtual/físico)
input_method_menu() {
    local TITLE="$1"
    local CURRENT_VALUE="$2"
    local RESULT_VAR
    local tmpfile

    CHOICE=$(dialog --menu "$TITLE\n\nEscolha o metodo de entrada:" 12 60 5 \
        1 "Teclado Virtual (Controle)" \
        2 "Teclado Padrao (USB/Fisico)" \
        3 "Voltar" \
        2>&1 >/dev/tty) || return 1

    case "$CHOICE" in
        1)
            RESULT_VAR="$(virtual_keyboard "$CURRENT_VALUE")" || return 1
            ;;
        2)
            tmpfile="$(mktemp /tmp/scraper_input.XXXXXX)"
            dialog --inputbox "Digite o texto:" 10 60 "$CURRENT_VALUE" \
                < /dev/tty > /dev/tty 2> "$tmpfile" || {
                rm -f "$tmpfile"
                return 1
            }
            RESULT_VAR="$(sed -n '1p' "$tmpfile")"
            rm -f "$tmpfile"
            ;;
        3)
            return 1
            ;;
    esac

    [ -z "$RESULT_VAR" ] && return 1
    echo "$RESULT_VAR"
    return 0
}

###############################################################################
# CREDENCIAIS
###############################################################################

get_scraper_credentials() {

USER=$(grep 'ScreenScraperUser' "$ES_SETTINGS" 2>/dev/null | sed -n 's/.*value="\([^"]*\)".*/\1/p')
PASS=$(grep 'ScreenScraperPass' "$ES_SETTINGS" 2>/dev/null | sed -n 's/.*value="\([^"]*\)".*/\1/p')

[ -z "$USER" ] && return 1
[ -z "$PASS" ] && return 1

return 0
}

configure_credentials() {

CURRENT_USER=$(grep 'ScreenScraperUser' "$ES_SETTINGS" 2>/dev/null | sed -n 's/.*value="\([^"]*\)".*/\1/p')
CURRENT_PASS=$(grep 'ScreenScraperPass' "$ES_SETTINGS" 2>/dev/null | sed -n 's/.*value="\([^"]*\)".*/\1/p')

NEW_USER="$(input_method_menu "USUARIO ScreenScraper" "$CURRENT_USER")" || return
[ -z "$NEW_USER" ] && return

NEW_PASS="$(input_method_menu "SENHA ScreenScraper" "$CURRENT_PASS")" || return
[ -z "$NEW_PASS" ] && return

sed -i "s|ScreenScraperUser\" value=\".*\"|ScreenScraperUser\" value=\"$NEW_USER\"|" "$ES_SETTINGS"
sed -i "s|ScreenScraperPass\" value=\".*\"|ScreenScraperPass\" value=\"$NEW_PASS\"|" "$ES_SETTINGS"

sync
msg "Credenciais atualizadas com sucesso."
}

###############################################################################
# SISTEMAS
###############################################################################

get_systems() {

awk '
/<system>/ { inside=1 }
/<\/system>/ {
if(name && path && platform){
print name "|" path "|" platform
}
name=""; path=""; platform=""; inside=0
}
inside {
if($0 ~ /<name>/){ gsub(/.*<name>|<\/name>.*/,""); name=$0 }
if($0 ~ /<path>/){ gsub(/.*<path>|<\/path>.*/,""); path=$0 }
if($0 ~ /<platform>/){ gsub(/.*<platform>|<\/platform>.*/,""); platform=$0 }
}
' "$ES_SYSTEMS"
}

get_system_id() {
case "$1" in

# Nintendo
nes) echo 3 ;;
fds) echo 106 ;;
snes) echo 4 ;;
n64) echo 14 ;;
gamecube|gc) echo 13 ;;
wii) echo 16 ;;
nds) echo 15 ;;
3ds) echo 17 ;;
gb) echo 8 ;;
gbc) echo 9 ;;
gba) echo 12 ;;
virtualboy) echo 11 ;;
gameandwatch) echo 52 ;;
pokemini) echo 211 ;;
satellaview) echo 107 ;;

# Sega
mastersystem) echo 2 ;;
megadrive|genesis) echo 1 ;;
segacd) echo 20 ;;
sega32x) echo 19 ;;
gamegear) echo 21 ;;
dreamcast) echo 23 ;;
saturn) echo 22 ;;
naomi) echo 56 ;;
atomiswave) echo 53 ;;
sg-1000) echo 109 ;;
sc-3000) echo 108 ;;

# Sony
psx) echo 57 ;;
ps2) echo 58 ;;
psp) echo 61 ;;

# SNK
neogeo) echo 142 ;;
neogeocd) echo 70 ;;
ngp) echo 25 ;;
ngpc) echo 82 ;;

# NEC
pcengine) echo 31 ;;
pcenginecd) echo 114 ;;
supergrafx) echo 105 ;;
pcfx) echo 72 ;;
tg16) echo 31 ;;
tg16cd) echo 114 ;;

# Atari
atari2600) echo 26 ;;
atari5200) echo 40 ;;
atari7800) echo 41 ;;
atarilynx) echo 28 ;;
atarijaguar) echo 27 ;;
atarist) echo 42 ;;
atari800) echo 43 ;;

# Commodore
c64) echo 66 ;;
c128) echo 75 ;;
vic20) echo 73 ;;
amiga) echo 64 ;;
amigacd32) echo 129 ;;
c16) echo 74 ;;

# MSX
msx) echo 113 ;;
msx2) echo 116 ;;

# Arcade
arcade|mame) echo 75 ;;
cps1) echo 6 ;;
cps2) echo 7 ;;
cps3) echo 8 ;;
fbneo) echo 75 ;;
neogeo) echo 142 ;;

# Panasonic / Others
3do) echo 29 ;;
cdi) echo 130 ;;

# Bandai
wonderswan) echo 45 ;;
wonderswancolor) echo 46 ;;
sufami) echo 4 ;;

# Sinclair
zxspectrum) echo 76 ;;
zx81) echo 77 ;;

# Sharp
x68000) echo 79 ;;
x1) echo 80 ;;

# PC
pc|pc98|pcengine|dos|ports|ports_script|ports_scripts) echo 135 ;;
quake2) echo 135 ;;
quake3) echo 135 ;;
doom3) echo 135 ;;
wolf3d) echo 135 ;;
ecwolf) echo 135 ;;
prboom) echo 135 ;;
scummvm) echo 135 ;;

# Handheld / Others
intellivision) echo 115 ;;
colecovision) echo 183 ;;
vectrex) echo 102 ;;
odyssey2|videopac) echo 104 ;;
supervision) echo 63 ;;
megaduck) echo 180 ;;
karaoke) echo "" ;;
tic80) echo 222 ;;
pico8) echo 234 ;;
openbor) echo "" ;;
ports) echo "" ;;
ikemen) echo "" ;;
vircon32) echo "" ;;
solarus) echo "" ;;
wasm4) echo "" ;;
freej2me) echo "" ;;
zmachine) echo "" ;;
gmloader) echo "" ;;
easyrpg) echo "" ;;
imageviewer) echo "" ;;
mplayer) echo "" ;;
music) echo "" ;;
setup) echo "" ;;

# Fallback
*) echo "" ;;

esac
}

normalize_desc_to_single_line() {

GAMELIST="$1/gamelist.xml"
TMP="$GAMELIST.tmp"

awk '
BEGIN { in_desc=0 }

{
    if ($0 ~ /<desc>/) {
        in_desc=1
    }

    if (in_desc) {
        gsub(/\r/, "")
        printf "%s", $0

        if ($0 ~ /<\/desc>/) {
            printf "\n"
            in_desc=0
        }
        next
    }

    print
}
' "$GAMELIST" > "$TMP"

mv "$TMP" "$GAMELIST"
sync
}

check_missing_images() {

FOLDER="$1"
SYSTEM_ID="$2"
SYSTEM_ROOT="$3"
GAMELIST="$SYSTEM_ROOT/gamelist.xml"

[ ! -f "$GAMELIST" ] && {
    msg "gamelist.xml nao encontrado."
    return
}

FOUND_MISSING=0

while IFS= read -r ROM; do

    case "$ROM" in
    *.png|*.jpg|*.jpeg|*.xml|*.txt|*.cfg|*.srm|*.sav) continue ;;
    esac

    REL_PATH="${ROM#$SYSTEM_ROOT/}"

    if grep -qF "<path>./$REL_PATH</path>" "$GAMELIST"; then

        GAME_BLOCK=$(awk "/<path>\\.\\/$REL_PATH<\\/path>/,/<\\/game>/" "$GAMELIST")
        IMAGE_PATH=$(echo "$GAME_BLOCK" | grep "<image>" | sed 's/.*<image>\(.*\)<\/image>.*/\1/')

        if [ -z "$IMAGE_PATH" ]; then
            dialog --infobox "Sem imagem: $(basename "$ROM")" 5 50
            scrape_game "$ROM" "$SYSTEM_ID" "$SYSTEM_ROOT"
            FOUND_MISSING=1
            continue
        fi

        CLEAN_IMAGE="${IMAGE_PATH#./}"
        FULL_IMAGE_PATH="$SYSTEM_ROOT/$CLEAN_IMAGE"

        if [ ! -f "$FULL_IMAGE_PATH" ]; then
            dialog --infobox "Imagem ausente: $(basename "$ROM")" 5 50
            scrape_game "$ROM" "$SYSTEM_ID" "$SYSTEM_ROOT"
            FOUND_MISSING=1
        fi

    else
        dialog --infobox "Nao listado: $(basename "$ROM")" 5 50
        scrape_game "$ROM" "$SYSTEM_ID" "$SYSTEM_ROOT"
        FOUND_MISSING=1
    fi

done < <(find "$FOLDER" -type f | sort -f)

if [ "$FOUND_MISSING" -eq 0 ]; then
    msg "Todos os jogos possuem imagem valida."
else
    msg "Verificacao concluida."
fi

}

clear_full_cache() {

dialog --infobox "Removendo cache total do Skyscraper..." 5 50
sleep 1

[ -d /storage/.skyscraper/cache ] && rm -rf /storage/.skyscraper/cache

sync

dialog --msgbox "Cache total removido com sucesso." 6 50
}


translate_gamelist_ptbr() {

FILE="$1"

if [ ! -f "$FILE" ]; then
    dialog --msgbox "gamelist.xml nao encontrado:\n$FILE" 7 50
    return
fi

API_KEY=$(grep '"api_key"' /storage/.picoclaw/config.json | sed -n '1s/.*"api_key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

###############################################################################
# TESTE DE INTERNET E API
###############################################################################

[ -z "$API_KEY" ] && {
    dialog --msgbox "API da OpenAI nao encontrada." 6 40
    return
}

ping -c1 -W2 api.openai.com >/dev/null 2>&1 || {
    dialog --msgbox "Sem conexao com internet.\n\nTraducao cancelada." 7 50
    return
}

###############################################################################
# BACKUP DE SEGURANCA
###############################################################################

BACKUP="${FILE}.backup"
cp "$FILE" "$BACKUP"

dialog --infobox "Traduzindo descricoes...\nAguarde..." 5 50

###############################################################################
# PYTHON TRANSLATOR
###############################################################################

python3 - "$FILE" "$API_KEY" << 'PY'
import sys, json, urllib.request, xml.etree.ElementTree as ET, time

file = sys.argv[1]
api_key = sys.argv[2]

tree = ET.parse(file)
root = tree.getroot()

descs = root.findall(".//desc")
total = len(descs)

def translate(text):
    payload = {
        "model": "gpt-4o-mini",
        "messages": [
            {"role":"user","content":"Translate to Brazilian Portuguese:\n"+text}
        ]
    }

    req = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=json.dumps(payload).encode(),
        headers={
            "Content-Type":"application/json",
            "Authorization":"Bearer "+api_key
        }
    )

    try:
        with urllib.request.urlopen(req) as r:
            data = json.loads(r.read().decode())
            return data["choices"][0]["message"]["content"].strip()
    except:
        return text

for i,desc in enumerate(descs,1):

    text = desc.text
    if not text or text.strip()=="":
        continue

    translated = translate(text)
    desc.text = translated

    print(f"Traduzindo {i}/{total}")

tree.write(file, encoding="utf-8", xml_declaration=True)
PY


if [ $? -ne 0 ]; then
    mv "$BACKUP" "$FILE"
    dialog --msgbox "Erro durante a traducao.\nBackup restaurado." 7 50
    return
fi

dialog --msgbox "Traducao concluída." 6 40
}

# Corrige entries em que ScreenScraper retornou nome do jogo ERRADO (ex:
# "3D Asteroids" matchado como "Asteroids"). Heurística: se o basename do
# <path> tem palavras que o <name> do scraper NÃO tem (tipo "3D", "II",
# "Remix", etc), substitui name pelo basename do arquivo (limpo).
fix_misnamed_games() {
    local GAMELIST="$1"
    [ ! -f "$GAMELIST" ] && return

    python3 - "$GAMELIST" <<'PYFIX'
import sys, re, os
import xml.etree.ElementTree as ET

gamelist = sys.argv[1]
try:
    tree = ET.parse(gamelist)
except Exception:
    sys.exit(0)
root = tree.getroot()

def tokens(s):
    # extrai tokens relevantes (preserva dígitos, remove pontuação)
    return set(re.findall(r'[A-Za-z0-9]+', s.lower()))

fixed = 0
for game in root.findall('game'):
    path = game.find('path')
    name = game.find('name')
    if path is None or name is None or not path.text or not name.text:
        continue
    # basename sem extensão
    base = os.path.splitext(os.path.basename(path.text))[0]
    path_tokens = tokens(base)
    name_tokens = tokens(name.text)
    # Se tem palavra no filename que NÃO está no nome, scraper errou
    # (ignora tokens curtos que são ruído: year entre ()) — na verdade
    # year também é palavra, se sumir tb é wrong)
    missing = path_tokens - name_tokens
    # Só corrige se houver palavras distintivas faltando (diff >= 1
    # token diferente). Palavras genéricas tipo "the" não importam aqui
    # pq se o name tiver "The" ele também entra no name_tokens.
    if missing:
        name.text = base
        fixed += 1

if fixed:
    tree.write(gamelist, encoding='utf-8', xml_declaration=True)
    print(f"fix_misnamed_games: corrigidos {fixed} entries")
PYFIX
}

force_rebuild() {

SYSTEM_ROOT="$1"

USER=$(grep 'ScreenScraperUser' "$ES_SETTINGS" | sed -n 's/.*value="\([^"]*\)".*/\1/p')
PASS=$(grep 'ScreenScraperPass' "$ES_SETTINGS" | sed -n 's/.*value="\([^"]*\)".*/\1/p')

[ -z "$USER" ] && { msg "Usuario nao configurado."; return; }
[ -z "$PASS" ] && { msg "Senha nao configurada."; return; }

PLATFORM=$(basename "$SYSTEM_ROOT")

dialog --infobox "Removendo cache e dados antigos..." 5 50

# Remove gamelist e media
rm -f "$SYSTEM_ROOT/gamelist.xml"
rm -rf "$SYSTEM_ROOT/media"

# Remove cache real do EmuELEC
rm -rf /storage/.skyscraper/cache/$PLATFORM

sync

dialog --infobox "Rebaixando tudo do zero..." 5 50

# === MESMO COMANDO QUE FUNCIONA NA PASTA INTEIRA ===
Skyscraper \
-p "$PLATFORM" \
-s screenscraper \
-u "$USER:$PASS" \
-i "$SYSTEM_ROOT" \
-t 1 \
--verbosity 0

# Gera gamelist
Skyscraper \
-p "$PLATFORM" \
-f emulationstation \
-i "$SYSTEM_ROOT" \
--flags relative

# Corrige names errados que o ScreenScraper possa ter retornado
# (ex: "3D Asteroids" matchado como "Asteroids")
fix_misnamed_games "$SYSTEM_ROOT/gamelist.xml"

sync

msg "Recriado com sucesso."

}

###############################################################################
# SCRAPER
###############################################################################

scrape_game() {

ROM_PATH="$1"
SYSTEM_ROOT="$3"

case "$ROM_PATH" in
*.png|*.jpg|*.jpeg|*.xml|*.txt|*.cfg|*.srm|*.sav) return ;;
esac

USER=$(grep 'ScreenScraperUser' "$ES_SETTINGS" | sed -n 's/.*value="\([^"]*\)".*/\1/p')
PASS=$(grep 'ScreenScraperPass' "$ES_SETTINGS" | sed -n 's/.*value="\([^"]*\)".*/\1/p')

[ -z "$USER" ] && return
[ -z "$PASS" ] && return

PLATFORM=$(basename "$SYSTEM_ROOT")

case "$PLATFORM" in
ports|ports_script|ports_scripts|openbor|scummvm|doom|quake)
PLATFORM="pc"
;;
esac

dialog --infobox "Scrapando: $(basename "$ROM_PATH")" 5 50

# Skyscraper por default JÁ coleta screenshot/cover/wheel/marquee.
# Usamos flags NEGATIVAS pra desligar (noscreenshots, nocovers, nowheels)
# e 'videos' pra LIGAR (desligado por padrão).
FLAGS="nosubdirs"
[ "$SCRAPER_VIDEO"      = "on"  ] && FLAGS="$FLAGS,videos"
[ "$SCRAPER_SCREENSHOT" = "off" ] && FLAGS="$FLAGS,noscreenshots"
[ "$SCRAPER_BOXART"     = "off" ] && FLAGS="$FLAGS,nocovers"
[ "$SCRAPER_WHEEL"      = "off" ] && FLAGS="$FLAGS,nowheels"

# Coleta apenas esse ROM — Skyscraper exige o nome do ROM no final da
# linha de comando quando --query é usado (arg posicional final).
ROM_NAME="$(basename "$ROM_PATH")"
(
    cd "$SYSTEM_ROOT" && \
    Skyscraper \
        -p "$PLATFORM" \
        -s screenscraper \
        -u "$USER:$PASS" \
        -i "$SYSTEM_ROOT" \
        --query "romnom=$ROM_NAME" \
        --flags "$FLAGS" \
        -t 1 \
        --verbosity 0 \
        "$ROM_NAME"
)

# Gera saída final
Skyscraper \
-p "$PLATFORM" \
-f emulationstation \
-i "$SYSTEM_ROOT" \
--flags relative

# Corrige names errados que o ScreenScraper possa ter retornado
# (ex: "3D Asteroids" matchado como "Asteroids")
fix_misnamed_games "$SYSTEM_ROOT/gamelist.xml"

sync
}

scrape_folder_recursive() {

SYSTEM_ROOT="$3"

USER=$(grep 'ScreenScraperUser' "$ES_SETTINGS" | sed -n 's/.*value="\([^"]*\)".*/\1/p')
PASS=$(grep 'ScreenScraperPass' "$ES_SETTINGS" | sed -n 's/.*value="\([^"]*\)".*/\1/p')

[ -z "$USER" ] && return
[ -z "$PASS" ] && return

PLATFORM=$(basename "$SYSTEM_ROOT")

case "$PLATFORM" in
ports|ports_script|ports_scripts|openbor|scummvm|doom|quake)
PLATFORM="pc"
;;
esac

# Força limpeza de cache da plataforma antes de recomeçar
# (evita que dados obsoletos/parciais interfiram com novo scrape)
dialog --infobox "Limpando cache Skyscraper da plataforma..." 5 60
rm -rf "/storage/.skyscraper/cache/$PLATFORM" 2>/dev/null
sync

dialog --infobox "Scrapando pasta inteira..." 5 50

# Flags Skyscraper: negativas pra desligar defaults, 'videos' pra ligar
FLAGS=""
[ "$SCRAPER_VIDEO"      = "on"  ] && FLAGS="${FLAGS:+$FLAGS,}videos"
[ "$SCRAPER_SCREENSHOT" = "off" ] && FLAGS="${FLAGS:+$FLAGS,}noscreenshots"
[ "$SCRAPER_BOXART"     = "off" ] && FLAGS="${FLAGS:+$FLAGS,}nocovers"
[ "$SCRAPER_WHEEL"      = "off" ] && FLAGS="${FLAGS:+$FLAGS,}nowheels"

# Coleta tudo
Skyscraper \
-p "$PLATFORM" \
-s screenscraper \
-u "$USER:$PASS" \
-i "$SYSTEM_ROOT" \
${FLAGS:+--flags "$FLAGS"} \
-t 1 \
--verbosity 0

# Gera saída final
Skyscraper \
-p "$PLATFORM" \
-f emulationstation \
-i "$SYSTEM_ROOT" \
--flags relative

# Corrige names errados que o ScreenScraper possa ter retornado
# (ex: "3D Asteroids" matchado como "Asteroids")
fix_misnamed_games "$SYSTEM_ROOT/gamelist.xml"

sync
}

###############################################################################
# NAVEGACAO
###############################################################################

navigate_folder() {

CURRENT_PATH="$1"
SYSTEM_ID="$2"
SYSTEM_ROOT="$3"

while true; do

# MENU PRINCIPAL DA PASTA
ACTION=$(dialog --menu "Pasta: $(basename "$CURRENT_PATH")" 20 60 7 \
1 "Abrir pasta" \
2 "Scraper pasta inteira" \
3 "Verificar jogos sem imagens" \
4 "Scraper FORCADO (recriar tudo)" \
5 "Traduzir descricoes para PT-BR POR IA" \
0 "Voltar" \
2>&1 >/dev/tty)

case "$ACTION" in
"1")
    ;;
"2")
    scrape_folder_recursive "$CURRENT_PATH" "$SYSTEM_ID" "$SYSTEM_ROOT"
    msg "Concluido."
    continue
;;
"3")
    check_missing_images "$CURRENT_PATH" "$SYSTEM_ID" "$SYSTEM_ROOT"
    continue
;;
"4")
    force_rebuild "$SYSTEM_ROOT"
    msg "Finalizado."
    continue
;;
"5")
    translate_gamelist_ptbr "$SYSTEM_ROOT/gamelist.xml"
    continue
;;
"0")
    return
;;
*)
    continue
;;
esac


# LISTAR CONTEÚDO DA PASTA
ITEMS=$(find "$CURRENT_PATH" -mindepth 1 -maxdepth 1 | sort -f)

MENU=()
INDEX=0

while IFS= read -r LINE; do
NAME=$(basename "$LINE")
if [ -d "$LINE" ]; then
MENU+=("$INDEX" "[PASTA] $NAME")
else
MENU+=("$INDEX" "$NAME")
fi
INDEX=$((INDEX+1))
done <<< "$ITEMS"

MENU+=("999" "Voltar")

CHOICE=$(dialog --menu "Local:\n$CURRENT_PATH" 25 70 15 "${MENU[@]}" 2>&1 >/dev/tty)

[ -z "$CHOICE" ] && continue
[ "$CHOICE" = "999" ] && continue

SELECTED=$(echo "$ITEMS" | sed -n "$((CHOICE+1))p")

if [ -d "$SELECTED" ]; then
    navigate_folder "$SELECTED" "$SYSTEM_ID" "$SYSTEM_ROOT"
else
    scrape_game "$SELECTED" "$SYSTEM_ID" "$SYSTEM_ROOT"
    msg "Concluido."
fi

done
}

###############################################################################
# MENU PRINCIPAL
###############################################################################

validate_files

while true; do

CURRENT_USER=$(grep 'ScreenScraperUser' "$ES_SETTINGS" 2>/dev/null | sed -n 's/.*value="\([^"]*\)".*/\1/p')
[ -z "$CURRENT_USER" ] && CURRENT_USER="Nao definido"

choice=$(dialog --clear \
--title "BLACK RETRO ELITE - SCRAPER" \
--menu "Usuario: $CURRENT_USER" \
20 60 10 \
1 "Selecionar sistema" \
2 "Configurar usuario e senha" \
3 "Limpar cache TOTAL Skyscraper" \
4 "Configuracoes do Scraper" \
0 "Sair" \
2>&1 >/dev/tty)

case "$choice" in

1)

get_scraper_credentials || { msg "Configure usuario e senha primeiro."; continue; }

SYSTEMS=$(get_rom_systems)

MENU=()
INDEX=0

while IFS= read -r LINE; do
    NAME=$(basename "$LINE")
    MENU+=("$INDEX" "$NAME")
    INDEX=$((INDEX+1))
done <<< "$SYSTEMS"

CHOICE_SYS=$(dialog --menu "Selecione a pasta de ROMS" 20 60 12 "${MENU[@]}" 2>&1 >/dev/tty)
[ -z "$CHOICE_SYS" ] && continue

SYS_PATH=$(echo "$SYSTEMS" | sed -n "$((CHOICE_SYS+1))p")
SYS_NAME=$(basename "$SYS_PATH")

SYSTEM_PLATFORM=$(awk -v name="$SYS_NAME" '
/<system>/ { inside=1 }
/<\/system>/ { inside=0 }
inside {
    if ($0 ~ "<name>"name"</name>") found=1
    if (found && $0 ~ "<platform>") {
        gsub(/.*<platform>|<\/platform>.*/,"")
        print
        exit
    }
}
' "$ES_SYSTEMS")

if [ -z "$SYSTEM_PLATFORM" ]; then
    SYSTEM_PLATFORM="$SYS_NAME"
fi

SYSTEM_ID=$(get_system_id "$SYSTEM_PLATFORM")

if [ -z "$SYSTEM_ID" ]; then
    SYSTEM_ID="0"
fi

navigate_folder "$SYS_PATH" "$SYSTEM_ID" "$SYS_PATH"
;;

2)
    configure_credentials
;;

3)
    clear_full_cache
;;

4)
    scraper_settings_menu
;;

0)
    clear
    exit 0
;;

*)
    continue
;;

esac

done