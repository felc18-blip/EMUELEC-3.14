#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Black Retro Elite — Scraper Manager (wrapper)
# Mostra confirmação via ES, mata a ES e dispara o .start no TTY1.

. /etc/profile

ee_console enable

function scrape_confirm() {
    text_viewer -y -w -t "Black Retro Scraper" -f 24 -m \
"Isso vai fechar o EmulationStation e iniciar o Black Retro Scraper (interface dialog via Skyscraper + ScreenScraper).\n\nVocê precisa de teclado pra navegar no menu.\n\nDeseja continuar?"
    [[ $? == 21 ]] && start_scraper || exit 0
}

function start_scraper() {
    ee_console enable
    systemd-run bash /usr/bin/scripts/setup/black_retro_scraper.start
    systemctl stop emustation
}

scrape_confirm
