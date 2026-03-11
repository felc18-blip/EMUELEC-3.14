#!/bin/bash
. /etc/profile

ROMNAME="$1"
PLATFORM="gba"

CONFIG_DIR="/storage/.config/nanoboyadvance"
SYS_CONFIG="/usr/config/nanoboyadvance"
BIOS_DIR="/storage/roms/bios"

# Criar config persistente
if [ ! -d "${CONFIG_DIR}" ]; then
    mkdir -p "${CONFIG_DIR}"
    cp -r ${SYS_CONFIG}/* "${CONFIG_DIR}/"
fi

# Garantir pasta bios
mkdir -p "${BIOS_DIR}"

# Copiar BIOS se não existir
if [ ! -f "${BIOS_DIR}/gba_bios.bin" ]; then
    if [ -f "${SYS_CONFIG}/bios/gba_bios.bin" ]; then
        cp "${SYS_CONFIG}/bios/gba_bios.bin" "${BIOS_DIR}/"
    fi
fi

# Seleção de cores
CORES=$(get_setting "cores" "${PLATFORM}" "${ROMNAME##*/}")

if [ "${CORES}" = "little" ]; then
    EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]; then
    EMUPERF="${FAST_CORES}"
else
    unset EMUPERF
fi

exec ${EMUPERF} /usr/bin/NanoBoyAdvance "${ROMNAME}"