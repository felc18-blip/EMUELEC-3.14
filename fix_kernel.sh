#!/bin/bash

# --- CONFIGURAÇÃO DE CAMINHOS ---
BASE_DIR="/home/felipe/NextOS-Elite-Edition"
STAGING_DIR="/home/felipe/NextOS_Staging"
KERNEL_IMG="$BASE_DIR/build.EmuELEC-Amlogic-ce.aarch64/kernel.img"
LOGO_ORIGEM="$BASE_DIR/distributions/EmuELEC/splash/Amlogic-ng/boot-logo-1080.bmp.gz"
PLY_IMAGE_ORIGEM="$BASE_DIR/build.EmuELEC-Amlogic-old.aarch64-4/install_pkg/plymouth-lite-0.6.0/usr/bin/ply-image"

# --- OFFSETS (Decimal do seu Binwalk) ---
CPIO_START=6778880
DTB_START=13248512

# 1. Criando a estrutura de pastas (CRIANDO O STAGING JUNTO)
echo ">>> [NextOS Elite] Preparando o laboratório em $STAGING_DIR..."
mkdir -p "$STAGING_DIR"
WORK_DIR="$STAGING_DIR/cirurgia_kernel"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/initramfs_folder"

# 2. Verificação de Segurança
if [ ! -f "$KERNEL_IMG" ]; then
    echo "❌ ERRO: Kernel original não encontrado em $KERNEL_IMG"
    exit 1
fi

# 3. Fatiando o Kernel (Cirurgia Binária)
echo ">>> Fatiando o Kernel original..."
dd if="$KERNEL_IMG" bs=1 count=$CPIO_START of="$WORK_DIR/parte1_kernel.bin" status=none
dd if="$KERNEL_IMG" bs=1 skip=$CPIO_START count=$((DTB_START - CPIO_START)) of="$WORK_DIR/parte2_initramfs.cpio" status=none
dd if="$KERNEL_IMG" bs=1 skip=$DTB_START of="$WORK_DIR/parte3_dtbs.bin" status=none

# 4. Extraindo e Modificando o Initramfs
echo ">>> Abrindo o Initramfs para injeção..."
cd "$WORK_DIR/initramfs_folder"
cpio -idmv < "../parte2_initramfs.cpio" 2>/dev/null

echo ">>> Injetando Identidade Visual do NextOS..."
mkdir -p splash usr/bin
cp -v "$LOGO_ORIGEM" "splash/splash-1080.png"
cp -v "$PLY_IMAGE_ORIGEM" "usr/bin/ply-image"
chmod +x usr/bin/ply-image

# 5. Remontando e Unindo as Peças
echo ">>> Remontando o Initramfs e selando o Kernel..."
find . | cpio -H newc -o > "../parte2_novo.cpio" 2>/dev/null
cd ..

# O GRANDE FINAL: O Kernel Elite vai para a pasta de Staging
cat parte1_kernel.bin parte2_novo.cpio parte3_dtbs.bin > "$STAGING_DIR/kernel_NEXTOS_ELITE.img"

echo "------------------------------------------------"
echo "✅ MISSÃO CUMPRIDA, FELIPE!"
echo "Novo Kernel gerado em: $STAGING_DIR/kernel_NEXTOS_ELITE.img"
echo "Os arquivos temporários estão em: $WORK_DIR"
echo "------------------------------------------------"
