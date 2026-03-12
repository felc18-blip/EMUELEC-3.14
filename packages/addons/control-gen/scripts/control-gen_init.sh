#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

# 1. Ajustado para o caminho real
GPTK_DIR="/storage/.config/emuelec/configs/gptokeyb"

mkdir -p "$GPTK_DIR"

# 2. Link gamecontrollerdb.txt
if [ -f /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt ]; then
    ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt \
    "$GPTK_DIR/gamecontrollerdb.txt"
fi

# 3. Link gptokeyb
if [ -f /usr/bin/gptokeyb ]; then
    ln -sf /usr/bin/gptokeyb "$GPTK_DIR/gptokeyb"
fi

# 4. Run control-gen
if [ -x /usr/bin/control-gen ]; then
    /usr/bin/control-gen > "$GPTK_DIR/control.ini"
fi

# 5. Permissões
chmod 0755 "$GPTK_DIR"/* 2>/dev/null