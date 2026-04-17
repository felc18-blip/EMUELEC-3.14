# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="image"
PKG_LICENSE="GPL"
PKG_SITE="https://libreelec.tv"

# Incluídos: pigz:host (novo), hdparm, parted, usbutils, procps-ng, e2fsprogs e exfatprogs
PKG_DEPENDS_TARGET="toolchain squashfs-tools:host pigz:host dosfstools:host fakeroot:host kmod:host mtools:host populatefs:host libc gcc linux linux-drivers linux-firmware ${BOOTLOADER} busybox util-linux corefonts network misc-packages debug hdparm parted e2fsprogs exfatprogs usbutils procps-ng"

PKG_SECTION="virtual"
PKG_LONGDESC="Root package used to build and create complete image"

# Bash como shell padrão (Sempre incluído da base antiga)
PKG_DEPENDS_TARGET+=" bash"

# Editor de texto Nano (Novo recurso opcional)
[ "${NANO_EDITOR}" = "yes" ] && PKG_DEPENDS_TARGET+=" nano"

# Suporte Gráfico
[ ! "${DISPLAYSERVER}" = "no" ] && PKG_DEPENDS_TARGET+=" ${DISPLAYSERVER}"

# Suporte a Media Center
[ ! "${MEDIACENTER}" = "no" ] && PKG_DEPENDS_TARGET+=" mediacenter"

# Suporte a Áudio (ALSA, PulseAudio ou Pipewire)
[ "${ALSA_SUPPORT}" = "yes" ] && PKG_DEPENDS_TARGET+=" alsa"

[ "${PULSEAUDIO_SUPPORT}" = "yes" ] && PKG_DEPENDS_TARGET+=" pulseaudio"

[ "${PIPEWIRE_SUPPORT}" = "yes" ] && PKG_DEPENDS_TARGET+=" pipewire wireplumber"

if [ "${PULSEAUDIO_SUPPORT}" = "yes" -a "${PIPEWIRE_SUPPORT}" = "yes" ]; then
  die "PULSEAUDIO_SUPPORT and PIPEWIRE_SUPPORT cannot be enabled together"
fi

# Suporte a Montagem Automática (udevil)
[ "${UDEVIL}" = "yes" ] && PKG_DEPENDS_TARGET+=" udevil"

# Suporte a EXFAT (Driver e ferramentas extras)
[ "$EXFAT" = "yes" ] && PKG_DEPENDS_TARGET+=" exfat"

# Ferramentas de sistema de arquivo HFS (Mac)
[ "${HFSTOOLS}" = "yes" ] && PKG_DEPENDS_TARGET+=" diskdev_cmds"

# Suporte a NTFS (ntfs-3g)
[ "${NTFS3G}" = "yes" ] && PKG_DEPENDS_TARGET+=" ntfs-3g_ntfsprogs"

# Suporte a Controles Remotos
[ "${REMOTE_SUPPORT}" = "yes" ] && PKG_DEPENDS_TARGET+=" remote"

# Criação de imagem virtual (Generic x86)
[ "${PROJECT}" = "Generic" ] && PKG_DEPENDS_TARGET+=" virtual"

# Suporte ao Instalador de Sistema
[ "${INSTALLER_SUPPORT}" = "yes" ] && PKG_DEPENDS_TARGET+=" installer"

# Ferramentas de Teste e Desenvolvimento
[ "${TESTING}" = "yes" ] && PKG_DEPENDS_TARGET+=" testing"

# Suporte a pacotes OEM
[ "${OEM_SUPPORT}" = "yes" ] && PKG_DEPENDS_TARGET+=" oem"

true
