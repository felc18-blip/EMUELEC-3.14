#!/bin/bash

. /etc/profile
set_kill_keys "daedalusx64-sa"

# Config inicial
if [ ! -d "/storage/.config/DaedalusX64" ]; then
  cp -r "/usr/config/DaedalusX64" "/storage/.config/"
fi

# SaveStates
mkdir -p "/storage/roms/savestates/n64/daedalus"

# Links
rm -rf "/storage/.config/DaedalusX64/Roms"
ln -sf "/storage/roms/n64" "/storage/.config/DaedalusX64/Roms"

rm -rf "/storage/.config/DaedalusX64/SavesGames"
ln -sf "/storage/roms/n64" "/storage/.config/DaedalusX64/SavesGames"

rm -rf "/storage/.config/DaedalusX64/SaveStates"
ln -sf "/storage/roms/savestates/n64/daedalus" "/storage/.config/DaedalusX64/SaveStates"

# ES
GAME=$(basename "${1}")
PLATFORM=$(basename "${2}")

CORES=$(get_setting "cores" "${PLATFORM}" "${GAME}")
if [ "${CORES}" = "little" ]; then
  EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]; then
  EMUPERF="${FAST_CORES}"
else
  unset EMUPERF
fi

# Sync binário config (opcional)
if [ -f "/usr/config/DaedalusX64/daedalus" ]; then
  shasum1=$(sha1sum /usr/config/DaedalusX64/daedalus | awk '{print $1}')
  shasum2=$(sha1sum /storage/.config/DaedalusX64/daedalus 2>/dev/null | awk '{print $1}')

  if [ "$shasum1" != "$shasum2" ]; then
    cp "/usr/config/DaedalusX64/daedalus" "/storage/.config/DaedalusX64/"
  fi
fi

cd /storage/.config/DaedalusX64/

# 🔥 usa binário correto
${EMUPERF} /usr/bin/daedalusx64-sa "${1}"