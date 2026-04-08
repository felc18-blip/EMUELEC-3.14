#!/bin/sh

VIDEOMODE=$(cat /sys/class/display/mode | grep -o '[0-9]\+' | head -n 1)
if [ "${VIDEOMODE}" -lt "720" ]; then
    FSIZE=12
else
    FSIZE=30
fi

echo $FSIZE

