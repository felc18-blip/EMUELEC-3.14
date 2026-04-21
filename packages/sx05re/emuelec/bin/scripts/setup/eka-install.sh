#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present EmuELEC Team (https://github.com/EmuELEC/EmuELEC)

. /etc/profile

EKA_INSTALL_SCRIPT="/usr/bin/scripts/setup/EKA_INSTALL.py"

function ekainstall_confirm() {
    text_viewer -y -w -t "E K A 2 L 1   C O M M A N D E R" -f 24 -m "Welcome to the eka2l1 Commander.\n\nUse this tool to setup eka2l1, install firmware and .sis/.sisx apps, import pre-configured device folders, change the active device, create `.uid` launcher files for installed applications, and convert selected device folders and their contents to lowercase so EKA2L1 can access case-sensitive paths correctly.\n\nController Navigation:\n\n- D-Pad: Navigate menus\n- A / Start: Confirm selection\n- B: Go back\n- Select: Exit program\n\nContinue?"

    if [[ $? == 21 ]]; then
        if ekainstall_start; then
            text_viewer -w -t "EKA2L1 COMMANDER" -f 24 -m "\n\nLaunch eka2l1 via EmulationStation."
        else
            text_viewer -e -w -t "EKA2L1 COMMANDER FAILED" -f 24 -m "There has been an error!\n\nCheck /emuelec/logs/eka2l1-install.log for details."
        fi
    fi

    ee_console disable
}

function ekainstall_start() {
    ee_console enable

    TTY="/dev/tty1"
    [[ -w "$TTY" ]] || TTY="/dev/tty0"
    [[ -w "$TTY" ]] || TTY="/dev/console"

    exec <"$TTY" >"$TTY" 2>&1

    for b in /sys/class/graphics/fb0/blank /sys/class/graphics/fb1/blank; do
        [[ -w "$b" ]] && echo 0 >"$b"
    done

    if command -v setterm >/dev/null 2>&1; then
        setterm -blank 0 -powerdown 0 -powersave off >"$TTY" 2>/dev/null || true
    fi

    clear

    echo "======================================"
    echo "   E K A 2 L 1   C O M M A N D E R       "
    echo "======================================"
    echo ""
    echo "Starting..."
    echo ""

    if [[ ! -f "$EKA_INSTALL_SCRIPT" ]]; then
        echo "ERROR: EKA_INSTALL.py not found at $EKA_INSTALL_SCRIPT"
        echo ""
        ee_console disable
        return 1
    fi

    chmod +x "$EKA_INSTALL_SCRIPT"
    sleep 1

    rm -f /tmp/ekainstall.ret >/dev/null 2>&1

    if command -v openvt >/dev/null 2>&1; then
        openvt -c 1 -s -f -- /bin/sh -c "/usr/bin/python3 -u '$EKA_INSTALL_SCRIPT' 2>&1 | tee /emuelec/logs/eka2l1-install.log; echo \$? >/tmp/ekainstall.ret"
        setup_result=$(cat /tmp/ekainstall.ret 2>/dev/null || echo 1)
    else
        /usr/bin/python3 -u "$EKA_INSTALL_SCRIPT" 2>&1 | tee /emuelec/logs/eka2l1-install.log
        setup_result=${PIPESTATUS[0]}
    fi

    if [[ $setup_result == 0 ]]; then
        echo "EKA2L1 Commander completed successfully."
        ee_console disable
        rm -f /tmp/display >/dev/null 2>&1
        return 0
    else
        echo "EKA2L1 Commander exited with code: $setup_result"
        ee_console disable
        rm -f /tmp/display >/dev/null 2>&1
        return 1
    fi
}

ekainstall_confirm
