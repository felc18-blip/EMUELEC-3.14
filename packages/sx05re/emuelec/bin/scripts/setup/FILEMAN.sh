#!/bin/bash
# Launcher Fileman - Adaptado do seu modelo

# 1. Limpa os consoles para evitar lixo visual por baixo
clear > /dev/tty0 < /dev/null 2>&1
clear > /dev/tty1 < /dev/null 2>&1

# 2. Ativa o controle (usando o seu mapeamento de botões)
# Se o fileman não responder aos botões, o gptokeyb resolve!
gptokeyb -c "/emuelec/configs/gptokeyb/351Files.gptk" &
PID_GP=$!

# 3. Define o caminho dos recursos que o fileman precisa
export RES_PATH=/usr/share/fileman/res

# 4. Executa o binário diretamente (sem fbterm, pois ele é SDL2)
/usr/bin/fileman /storage/roms

# 5. Mata o processo do gptokeyb ao fechar o fileman
kill $PID_GP