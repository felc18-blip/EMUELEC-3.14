#!/bin/bash
set -uo pipefail
. /etc/profile

LOG="/tmp/btsetup.log"

ee_console enable

cleanup() {
  ee_console disable
  rm -f /tmp/display
}
trap cleanup EXIT

echo "Reset Bluetooth..."
bluetoothctl power off >/dev/null 2>&1
sleep 1
bluetoothctl power on >/dev/null 2>&1
sleep 2

# UI em background (essencial no ES)
text_viewer -w -t "BT AUTO" -f 24 -m "ESCANEANDO...\nPS + CRIANDO" &
TV_PID=$!

(
echo "scan on"
sleep 10
echo "scan off"
echo "devices"
sleep 2
echo "quit"
) | bluetoothctl > /tmp/btlog 2>&1

kill $TV_PID >/dev/null 2>&1 || true

echo "Separando dispositivos..."

ALL_DEVICES=$(grep "^Device" /tmp/btlog | grep -vi " TY$")

PRIORITY=""
OTHERS=""

while read -r line; do
  MAC=$(echo "$line" | awk '{print $2}')
  NAME=$(echo "$line" | cut -d' ' -f3-)

  if echo "$NAME" | grep -Eiq "dualsense|wireless controller|xbox|8bit|gamepad|ps4|ps5"; then
    PRIORITY="$PRIORITY $MAC"
  else
    OTHERS="$OTHERS $MAC"
  fi
done <<< "$ALL_DEVICES"

DEVICES="$PRIORITY $OTHERS"

if [ -z "$DEVICES" ]; then
  text_viewer -w -t "INFO" -m "Nenhum dispositivo encontrado"
  exit 0
fi

# UI conexão (background)
text_viewer -w -t "CONECTANDO" -f 24 -m "Tentando dispositivos..." &
TV_CONN_PID=$!

CONECTADOS=0

for MAC in $DEVICES; do
  echo "Tentando $MAC"

  (
    echo "pair $MAC"
    sleep 4
    echo "trust $MAC"
    sleep 2
    echo "connect $MAC"
    sleep 5
    echo "quit"
  ) | bluetoothctl >/dev/null 2>&1 || true

  if bluetoothctl info "$MAC" 2>/dev/null | grep -q "Connected: yes"; then
    echo "$MAC" > /storage/.config/btaudio.last
    CONECTADOS=$((CONECTADOS+1))
    break
  fi
done

kill $TV_CONN_PID >/dev/null 2>&1 || true

if [ "$CONECTADOS" -gt 0 ]; then
  text_viewer -w -t "SUCESSO" -f 24 -m "Controle conectado"
else
  text_viewer -w -t "ERRO" -f 24 -m "Falha ao conectar"
fi

exit 0
