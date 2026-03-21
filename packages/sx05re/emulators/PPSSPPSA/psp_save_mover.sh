#!/bin/bash

# cria estrutura de saves se não existir
if [ ! -d "/storage/roms/psp/PSP" ]; then
  mkdir -p "/storage/roms/psp/PSP"

  if [ -d "/storage/.config/ppsspp-sa/PSP/SAVEDATA" ]; then
    cp -r /storage/.config/ppsspp-sa/PSP/SAVEDATA \
          /storage/roms/psp/PSP/
  fi
fi

# savestates separados do SA
if [ ! -d "/storage/roms/savestates/psp/ppsspp-sa" ]; then
  mkdir -p /storage/roms/savestates/psp/ppsspp-sa

  if [ -d "/storage/.config/ppsspp-sa/PSP/PPSSPP_STATE" ]; then
    cp -r /storage/.config/ppsspp-sa/PSP/PPSSPP_STATE/* \
          /storage/roms/savestates/psp/ppsspp-sa/ 2>/dev/null
  fi
fi