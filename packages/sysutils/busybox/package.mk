# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="busybox"
PKG_VERSION="1.37.0"
PKG_SHA256="3311dff32e746499f4df0d5df04d7eb396382d7e108bb9250e7b519b837043a4"
PKG_LICENSE="GPL"
PKG_SITE="http://www.busybox.net"
PKG_URL="https://busybox.net/downloads/${PKG_NAME}-${PKG_VERSION}.tar.bz2"

# Restaurado PKG_DEPENDS_HOST e a lista completa do seu original
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain hdparm hd-idle dosfstools e2fsprogs zip usbutils parted procps-ng gptfdisk libtirpc cryptsetup"
PKG_DEPENDS_INIT="toolchain libtirpc"

PKG_LONGDESC="BusyBox combines tiny versions of many common UNIX utilities into a single small executable."
PKG_BUILD_FLAGS="-parallel +lto +size"

# nano text editor
if [ "${NANO_EDITOR}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" nano"
fi

# nfs support
if [ "${NFS_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" rpcbind"
fi

if [ "${DEVICE}" = "Amlogic-ng" ] || [ "${DEVICE}" = "Amlogic-no" ]; then
  PKG_DEPENDS_TARGET+=" pciutils"
fi

pre_build_target() {
  PKG_MAKE_OPTS_TARGET="ARCH=${TARGET_ARCH} \
                        HOSTCC=${HOST_CC} \
                        CROSS_COMPILE=${TARGET_PREFIX} \
                        KBUILD_VERBOSE=1 \
                        install"

  mkdir -p ${PKG_BUILD}/.${TARGET_NAME}
  cp -RP ${PKG_BUILD}/* ${PKG_BUILD}/.${TARGET_NAME}
}

pre_build_init() {
  PKG_MAKE_OPTS_INIT="ARCH=${TARGET_ARCH} \
                      HOSTCC=${HOST_CC} \
                      CROSS_COMPILE=${TARGET_PREFIX} \
                      KBUILD_VERBOSE=1 \
                      install"

  mkdir -p ${PKG_BUILD}/.${TARGET_NAME}-init
  cp -RP ${PKG_BUILD}/* ${PKG_BUILD}/.${TARGET_NAME}-init
}

configure_target() {
  cd ${PKG_BUILD}/.${TARGET_NAME}
    find_file_path config/busybox-target.conf
    cp ${FOUND_PATH} .config

    # set install dir
    sed -i -e "s|^CONFIG_PREFIX=.*$|CONFIG_PREFIX=\"${INSTALL}/usr\"|" .config

    # 🔥 VACINA 1: Desativa SHA HWACCEL (Kernel 3.14)
    sed -i -e "s|^CONFIG_SHA1_HWACCEL=y|# CONFIG_SHA1_HWACCEL is not set|" .config
    sed -i -e "s|^CONFIG_SHA256_HWACCEL=y|# CONFIG_SHA256_HWACCEL is not set|" .config

    if [ ! "${CRON_SUPPORT}" = "yes" ]; then
      sed -i -e "s|^CONFIG_CROND=.*$|# CONFIG_CROND is not set|" .config
      sed -i -e "s|^CONFIG_FEATURE_CROND_D=.*$|# CONFIG_FEATURE_CROND_D is not set|" .config
      sed -i -e "s|^CONFIG_CRONTAB=.*$|# CONFIG_CRONTAB is not set|" .config
      sed -i -e "s|^CONFIG_FEATURE_CROND_SPECIAL_TIMES=.*$|# CONFIG_FEATURE_CROND_SPECIAL_TIMES is not set|" .config
    fi

    if [ ! "${SAMBA_SUPPORT}" = yes ]; then
      sed -i -e "s|^CONFIG_FEATURE_MOUNT_CIFS=.*$|# CONFIG_FEATURE_MOUNT_CIFS is not set|" .config
    fi

    # optimize for size e inclusão tirpc
    CFLAGS=$(echo ${CFLAGS} | sed -e "s|-Ofast|-Os|")
    CFLAGS=$(echo ${CFLAGS} | sed -e "s|-O.|-Os|")
    CFLAGS+=" -I${SYSROOT_PREFIX}/usr/include/tirpc"

    # 🔥 VACINA 2: Definições CAN ausentes no 3.14
    CFLAGS+=" -DCAN_CTRLMODE_FD=0x04 -DCAN_CTRLMODE_FD_NON_ISO=0x08 -DCAN_CTRLMODE_PRESUME_ACK=0x10 -DIFLA_CAN_TERMINATION=11"

    LDFLAGS+=" -fwhole-program"
    yes "" | make oldconfig
}

configure_init() {
  cd ${PKG_BUILD}/.${TARGET_NAME}-init
    find_file_path config/busybox-init.conf
    cp ${FOUND_PATH} .config

    sed -i -e "s|^CONFIG_PREFIX=.*$|CONFIG_PREFIX=\"${INSTALL}/usr\"|" .config
    sed -i -e "s|^CONFIG_SHA1_HWACCEL=y|# CONFIG_SHA1_HWACCEL is not set|" .config
    sed -i -e "s|^CONFIG_SHA256_HWACCEL=y|# CONFIG_SHA256_HWACCEL is not set|" .config

    CFLAGS=$(echo ${CFLAGS} | sed -e "s|-Ofast|-Os|")
    CFLAGS=$(echo ${CFLAGS} | sed -e "s|-O.|-Os|")
    CFLAGS+=" -I${SYSROOT_PREFIX}/usr/include/tirpc"
    CFLAGS+=" -DCAN_CTRLMODE_FD=0x04 -DCAN_CTRLMODE_FD_NON_ISO=0x08 -DCAN_CTRLMODE_PRESUME_ACK=0x10 -DIFLA_CAN_TERMINATION=11"

    LDFLAGS+=" -fwhole-program"
    yes "" | make oldconfig
}

makeinstall_target() {
  # 1. Pastas base
  mkdir -p ${INSTALL}/usr/bin ${INSTALL}/usr/sbin ${INSTALL}/usr/lib/libreelec ${INSTALL}/usr/lib/systemd/system-generators ${INSTALL}/etc

  # 2. Lógica de EDID e Projetos (Garante a cópia dos scripts de vídeo)
  if [ "${TARGET_ARCH}" = "x86_64" ]; then
    [ -f "${PKG_DIR}/scripts/getedid" ] && cp ${PKG_DIR}/scripts/getedid ${INSTALL}/usr/bin
  else
    [ -f "${PKG_DIR}/scripts/dump-active-edids-drm" ] && cp ${PKG_DIR}/scripts/dump-active-edids-drm ${INSTALL}/usr/bin/dump-active-edids
  fi
  [ -f "${PKG_DIR}/scripts/create-edid-cpio" ] && cp ${PKG_DIR}/scripts/create-edid-cpio ${INSTALL}/usr/bin/

  # Suporte a RPi
  if [ "${PROJECT}" = "RPi" ]; then
    [ -f "${PKG_DIR}/scripts/update-bootloader-edid-rpi" ] && cp ${PKG_DIR}/scripts/update-bootloader-edid-rpi ${INSTALL}/usr/bin/update-bootloader-edid
    [ -f "${PKG_DIR}/scripts/getedid-drm" ] && cp ${PKG_DIR}/scripts/getedid-drm ${INSTALL}/usr/bin/getedid
  fi

  # Suporte Amlogic/Rockchip (Simplificado para aceitar Amlogic-old/ng)
  if echo "${PROJECT}" | grep -qE "Amlogic|Rockchip"; then
    [ -f "${PKG_DIR}/scripts/update-bootloader-edid-extlinux" ] && cp ${PKG_DIR}/scripts/update-bootloader-edid-extlinux ${INSTALL}/usr/bin/getedid 2>/dev/null || true
  fi

  # 3. Scripts Elite Edition (Incluindo getedid no loop e removendo apt-get redundante)
  for s in simple_zip.py createlog dthelper ledfix lsb_release sudo pastebinit vfd-clock convert_dtname pkgapp getedid; do
    [ -f "${PKG_DIR}/scripts/$s" ] && cp -f ${PKG_DIR}/scripts/$s ${INSTALL}/usr/bin/
  done

  # 4. Criação de Links Simbólicos
  cd ${INSTALL}/usr/bin
    if [ -f "dthelper" ]; then
      for l in dtfile dtflag dtname dtsoc; do ln -sf dthelper $l; done
    fi

    if [ -f "pkgapp" ]; then
      for l in apt apt-get dnf rpm yum; do ln -sf pkgapp $l; done
    fi

    if [ -f "pastebinit" ]; then
      sed -e "s/@DISTRONAME@-@OS_VERSION@/${DISTRONAME}-${OS_VERSION}/g" -i pastebinit 2>/dev/null || true
      ln -sf pastebinit paste
    fi

  # 5. Overlays e Systemd
  [ -f "${PKG_DIR}/scripts/kernel-overlays-setup" ] && cp ${PKG_DIR}/scripts/kernel-overlays-setup ${INSTALL}/usr/sbin/
  [ -f "${PKG_DIR}/scripts/functions" ] && cp ${PKG_DIR}/scripts/functions ${INSTALL}/usr/lib/libreelec/

  if [ -f "${PKG_DIR}/scripts/fs-resize" ]; then
    cp ${PKG_DIR}/scripts/fs-resize ${INSTALL}/usr/lib/libreelec/
    sed -e "s/@DISTRONAME@/${DISTRONAME}/g" -i ${INSTALL}/usr/lib/libreelec/fs-resize
  fi

  [ -f "${PKG_DIR}/scripts/libreelec-target-generator" ] && cp ${PKG_DIR}/scripts/libreelec-target-generator ${INSTALL}/usr/lib/systemd/system-generators/
  listcontains "${FIRMWARE}" "rpi-eeprom" && [ -f "${PKG_DIR}/scripts/rpi-flash-firmware" ] && cp ${PKG_DIR}/scripts/rpi-flash-firmware ${INSTALL}/usr/lib/libreelec

  # 6. Configurações Globais
  [ -f "${PKG_DIR}/config/profile" ] && cp ${PKG_DIR}/config/profile ${INSTALL}/etc
  [ -f "${PKG_DIR}/config/inputrc" ] && cp ${PKG_DIR}/config/inputrc ${INSTALL}/etc
  [ -f "${PKG_DIR}/config/suspend-modules.conf" ] && cp ${PKG_DIR}/config/suspend-modules.conf ${INSTALL}/etc

  touch ${INSTALL}/etc/fstab
  ln -sf /storage/.cache/systemd-machine-id ${INSTALL}/etc/machine-id
  ln -sf /proc/self/mounts ${INSTALL}/etc/mtab
  ln -sf /proc/sys/kernel/hostname ${INSTALL}/etc/hostname

  # 7. Limpeza do Link do Bash
  [ -L ${INSTALL}/usr/bin/bash ] && rm ${INSTALL}/usr/bin/bash
}

post_install() {
  echo "chmod 4755 ${INSTALL}/usr/bin/busybox" >> ${FAKEROOT_SCRIPT}
  echo "chmod 000 ${INSTALL}/usr/cache/shadow" >> ${FAKEROOT_SCRIPT}

  add_user root "${ROOT_PASSWORD}" 0 0 "Root User" "/storage" "/bin/sh"
  add_group root 0
  add_group users 100
  add_user nobody x 65534 65534 "Nobody" "/" "/bin/sh"
  add_group nogroup 65534

  enable_service fs-resize.service
  enable_service ledfix.service
  enable_service shell.service
  enable_service show-version.service
  enable_service vfd-clock.service
  enable_service var.mount
  enable_service locale.service
  listcontains "${FIRMWARE}" "rpi-eeprom" && enable_service rpi-flash-firmware.service

  if [ "${CRON_SUPPORT}" = "yes" ]; then
    mkdir -p ${INSTALL}/usr/lib/systemd/system
      cp ${PKG_DIR}/system.d.opt/cron.service ${INSTALL}/usr/lib/systemd/system
      enable_service cron.service
    mkdir -p ${INSTALL}/usr/share/services
      cp -P ${PKG_DIR}/default.d/*.conf ${INSTALL}/usr/share/services
      cp ${PKG_DIR}/system.d.opt/cron-defaults.service ${INSTALL}/usr/lib/systemd/system
      enable_service cron-defaults.service
  fi
}

makeinstall_init() {
  mkdir -p ${INSTALL}/bin
    ln -sf busybox ${INSTALL}/usr/bin/sh
    chmod 4755 ${INSTALL}/usr/bin/busybox

  mkdir -p ${INSTALL}/etc
    touch ${INSTALL}/etc/fstab
    ln -sf /proc/self/mounts ${INSTALL}/etc/mtab

  if find_file_path initramfs/platform_init; then
    cp ${FOUND_PATH} ${INSTALL}
    sed -i -e "s/@BOOT_LABEL@/${DISTRO_BOOTLABEL}/g" \
           -e "s/@DISK_LABEL@/${DISTRO_DISKLABEL}/g" \
           ${INSTALL}/platform_init
    chmod 755 ${INSTALL}/platform_init
  fi

  cp ${PKG_DIR}/scripts/functions ${INSTALL}
  cp ${PKG_DIR}/scripts/init ${INSTALL}
  sed -i -e "s/@DISTRONAME@/${DISTRONAME}/g" \
         -e "s/@KERNEL_NAME@/${KERNEL_NAME}/g" \
         -e "s/@SYSTEM_SIZE@/${SYSTEM_SIZE}/g" \
         ${INSTALL}/init
  chmod 755 ${INSTALL}/init
}
