#!/bin/bash
# BlackRetroOS - S905L Lite Hook

case "${1}" in
"before")
    # Garante que o limite de ficheiros abertos é alto para o DuckStation/NDS
    ulimit -n 4096
    
    # Configura a agressividade da Swap (ZRAM)
    echo 100 > /proc/sys/vm/swappiness
    ;;

"after")
    # Limpa a memória cache e liberta a ZRAM após fechar o jogo
    echo 3 > /proc/sys/vm/drop_caches
    ;;
esac

exit 0