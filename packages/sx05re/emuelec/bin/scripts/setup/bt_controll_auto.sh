
#!/bin/bash
set -uo pipefail
. /etc/profile

LOG="/tmp/bt_audio.log"

echo "Reset Bluetooth..."
bluetoothctl power off >/dev/null 2>&1
sleep 1
bluetoothctl power on >/dev/null 2>&1
sleep 2

# garante pulseaudio
pgrep -f "pulseaudio.*--system" >/dev/null || {
  pulseaudio --system --disallow-exit --disable-shm --log-level=error &>>"$LOG" &
  sleep 2
}

# UI
text_viewer -w -t "BT AUDIO" -f 22 -m "ESCANEANDO...\nAtive modo pareamento" &
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

echo "Processando dispositivos..."

# remove lixo tipo TY
DEVICES=$(grep "^Device" /tmp/btlog | grep -vi " TY$" | awk '{print $2}')

if [ -z "$DEVICES" ]; then
  text_viewer -w -t "ERRO" -m "Nenhum dispositivo encontrado"
  exit 0
fi

text_viewer -w -t "CONECTANDO" -f 22 -m "Tentando audio..." &
TV_CONN_PID=$!

for MAC in $DEVICES; do
  echo "Tentando $MAC"

  (
    echo "scan off"
    echo "pair $MAC"
    sleep 4
    echo "trust $MAC"
    sleep 2
    echo "connect $MAC"
    sleep 6
    echo "quit"
  ) | bluetoothctl >/dev/null 2>&1 || true

  if bluetoothctl info "$MAC" 2>/dev/null | grep -q "Connected: yes"; then

    BTID="${MAC//:/_}"
    CARD="bluez_card.$BTID"

    echo "Configurando áudio..."

    # espera aparecer no pulse
    for i in {1..10}; do
      pactl list cards short | grep -q "$CARD" && break
      sleep 1
    done

    pactl set-card-profile "$CARD" a2dp_sink >/dev/null 2>&1 || true

    SINK=$(pactl list short sinks | awk '{print $2}' | grep -E "bluez_sink.${BTID}" | head -n1)

    if [ -n "$SINK" ]; then
      pactl set-default-sink "$SINK" >/dev/null 2>&1
      pactl set-sink-volume "$SINK" 100% >/dev/null 2>&1

      echo "$MAC" > /storage/.config/btaudio.last

      kill $TV_CONN_PID >/dev/null 2>&1 || true
      text_viewer -w -t "SUCESSO" -f 22 -m "Audio conectado!"
      exit 0
    fi
  fi
done

kill $TV_CONN_PID >/dev/null 2>&1 || true
text_viewer -w -t "ERRO" -m "Nenhum audio conectado"

exit 0
