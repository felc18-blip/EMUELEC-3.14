#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

# BlackRetroOS - Performance & ZRAM Hook
. /etc/profile

case "${1}" in
"before")
    # 1. CPU em modo Performance
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    fi

    # 2. Ativar ZRAM (256MB)
    modprobe zram num_devices=1 2>/dev/null
    (
        sleep 1
        if [ -b /dev/zram0 ]; then
            swapoff /dev/zram0 2>/dev/null
            echo 1 > /sys/block/zram0/reset 2>/dev/null
            echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null || echo lzo > /sys/block/zram0/comp_algorithm
            echo 268435456 > /sys/block/zram0/disksize
            mkswap /dev/zram0 >/dev/null 2>&1
            swapon -p 100 /dev/zram0 2>/dev/null
            echo 100 > /proc/sys/vm/swappiness
        fi
    ) &

    # 3. Limite de arquivos para o Mono (PortMaster)
    ulimit -n 4096
    ;;

"after")
    # Aqui você pode colocar comandos para rodar após o boot
    ;;
esac

exit 0