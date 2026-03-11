#!/bin/bash

. /etc/profile

# Copy drastic files to .config
if [ ! -d "/storage/.config/drastic" ]; then
  mkdir -p /storage/.config/drastic/
  cp -r /usr/config/drastic/* /storage/.config/drastic/
fi

if [ ! -d "/storage/.config/drastic/system" ]; then
  mkdir -p /storage/.config/drastic/system
fi

for bios in nds_bios_arm9.bin nds_bios_arm7.bin nds_firmware.bin
do
  if [ ! -e "/storage/.config/drastic/system/${bios}" ]; then
     if [ -e "/storage/roms/bios/${bios}" ]; then
       ln -sf /storage/roms/bios/${bios} /storage/.config/drastic/system/${bios}
     fi
  fi
done

# Make savestate folder
if [ ! -d "/storage/roms/savestates/nds" ]; then
  mkdir -p /storage/roms/savestates/nds
fi

# Link savestates
rm -rf /storage/.config/drastic/savestates
ln -sf /storage/roms/savestates/nds /storage/.config/drastic/savestates

# Link saves
rm -rf /storage/.config/drastic/backup
ln -sf /storage/roms/nds /storage/.config/drastic/backup

cd /storage/.config/drastic/

@HOTKEY@
@LIBEGL@

$GPTOKEYB "drastic" -c "/storage/.config/emuelec/configs/gptokeyb/drastic.gptk" &
/usr/config/drastic/drastic "$1" >/dev/null 2>&1
killall gptokeyb 2>/dev/null
