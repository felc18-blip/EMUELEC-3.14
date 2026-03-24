#!/bin/bash

. /etc/profile

EMU="@EMU@"
ROM="$1"

# diretório padrão
CONFIG_DIR="/storage/.config/vice"
mkdir -p ${CONFIG_DIR}

# opções base
OPTS="-fullscreen"

# detecta tipo de mídia
case "${ROM,,}" in
  *.d64|*.d71|*.d81)
    OPTS="${OPTS} -autostart \"${ROM}\""
  ;;
  *.tap|*.t64)
    OPTS="${OPTS} -autostart \"${ROM}\""
  ;;
  *.crt)
    OPTS="${OPTS} -cartcrt \"${ROM}\""
  ;;
  *.prg|*.p00)
    OPTS="${OPTS} -autostart \"${ROM}\""
  ;;
  *)
    OPTS="${OPTS} \"${ROM}\""
  ;;
esac

# executa
exec ${EMU} ${OPTS}