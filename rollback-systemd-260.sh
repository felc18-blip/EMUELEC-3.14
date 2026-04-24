#!/bin/bash
# NextOS rollback script — reverte systemd 260.1 → 257.13
# Criado em 2026-04-24 após experimento de bump do systemd para a versão do upstream LibreELEC.
# Rode este script a partir de /home/felipe/NextOS-Elite-Edition.

set -euo pipefail

BACKUP="/home/felipe/NextOS-Elite-Edition-backups/systemd-257.13-20260424-105254"
NEXTOS="/home/felipe/NextOS-Elite-Edition"
PROJECT="Amlogic-ce"
DEVICE="Amlogic-old"
ARCH="aarch64"

if [ ! -d "$BACKUP/systemd" ] || [ ! -d "$BACKUP/lib32-systemd-libs" ]; then
  echo "ERRO: backup não encontrado em $BACKUP"
  exit 1
fi

cd "$NEXTOS"

echo "==> Restaurando packages/sysutils/systemd/ do backup"
rm -rf packages/sysutils/systemd
cp -a "$BACKUP/systemd" packages/sysutils/systemd

echo "==> Restaurando packages/lib32/sysutils/lib32-systemd-libs/ do backup"
rm -rf packages/lib32/sysutils/lib32-systemd-libs
cp -a "$BACKUP/lib32-systemd-libs" packages/lib32/sysutils/lib32-systemd-libs

echo "==> Limpando artefatos do build com versão 260.1"
PROJECT="$PROJECT" DEVICE="$DEVICE" ARCH="$ARCH" ./scripts/clean systemd
PROJECT="$PROJECT" DEVICE="$DEVICE" ARCH="$ARCH" ./scripts/clean lib32-systemd-libs

echo ""
echo "==> Rollback concluído. Próximo passo:"
echo "    PROJECT=$PROJECT DEVICE=$DEVICE ARCH=$ARCH ./scripts/image"
echo ""
echo "    (ou ./scripts/build systemd para apenas re-compilar o pacote)"
