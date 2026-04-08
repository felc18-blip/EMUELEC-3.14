#!/bin/sh

# Mata instâncias travadas
killall -9 retroarch 2>/dev/null

# Pequena pausa
sleep 1

# Executa RetroArch
/usr/bin/retroarch "$@"

# Garante saída limpa
sleep 1
killall -9 retroarch 2>/dev/null
