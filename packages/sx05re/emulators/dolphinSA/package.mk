# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="dolphinSA"
PKG_VERSION="3c4d4fcd09173ea070dc812ab5d64ca3a3af5f29"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/dolphin-emu/dolphin"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain qt-everywhere libevdev"
PKG_LONGDESC="Dolphin is a GameCube / Wii emulator, allowing you to play games for these two platforms on PC with improvements. "
PKG_BUILD_FLAGS="lto"

# NextOS Amlogic-old: tuning agressivo Cortex-A53. -mcpu=cortex-a53 ativa
# microarchitecture-specific scheduling; -ftree-vectorize roda autovectoriza-
# tion que NEON na A53 aproveita; -funroll-loops ajuda hot loops do JIT e
# do software rasterizer.
if [ "${DEVICE}" == "Amlogic-old" ]; then
  TARGET_CFLAGS+=" -mcpu=cortex-a53 -mtune=cortex-a53 -ftree-vectorize -funroll-loops"
  TARGET_CXXFLAGS+=" -mcpu=cortex-a53 -mtune=cortex-a53 -ftree-vectorize -funroll-loops"
fi

# Configure CMake for LTO with BFD linker
PKG_CMAKE_OPTS_TARGET=" -DENABLE_LTO=ON \
                        -DCMAKE_EXE_LINKER_FLAGS='-fuse-ld=bfd' \
                        -DCMAKE_SHARED_LINKER_FLAGS='-fuse-ld=bfd' \
                        -DDISTRIBUTOR='EmuELEC' \
                        -DBUILD_SHARED_LIBS=OFF \
                        -DTHREADS_PTHREAD_ARG=OFF \
                        -DENABLE_FBDEV=ON \
                        -DENABLE_EGL=ON \
                        -DENABLE_X11=OFF \
                        -DENABLE_NOGUI=ON \
                        -DUSE_DISCORD_PRESENCE=OFF \
                        -DENABLE_QT=OFF \
                        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                        -DUSE_SYSTEM_FMT=OFF \
                        -DCMAKE_BUILD_TYPE=Release"

pre_configure_target() {
  if [ "${DEVICE}" == "Amlogic-old" ]; then
    # Kernel 3.14 nao tem INPUT_PROP_ACCELEROMETER nos headers do sysroot.
    # Coloco input-event-codes.h em PKG_BUILD/include/linux/ e adiciono -I
    # no CXXFLAGS (apenas), patchando evdev.cpp pra incluir explicitamente.
    # Evita conflito com KeyboardStatus.h (que tem KEY_A/KEY_B etc).
    mkdir -p ${PKG_BUILD}/include/linux
    cp -f $(get_build_dir libevdev)/include/linux/linux/input-event-codes.h \
          ${PKG_BUILD}/include/linux/input-event-codes.h 2>/dev/null || true
    export CFLAGS="${CFLAGS} -I${PKG_BUILD}/include"
    export CXXFLAGS="${CXXFLAGS} -I${PKG_BUILD}/include"
    # Patch evdev.cpp: adiciona include explicito antes do uso de
    # INPUT_PROP_ACCELEROMETER. Sem isso, libevdev.h → linux/input.h do
    # 3.14 nao tem o define.
    EVDEV_CPP="${PKG_BUILD}/Source/Core/InputCommon/ControllerInterface/evdev/evdev.cpp"
    if [ -f "${EVDEV_CPP}" ] && ! grep -q "input-event-codes.h" "${EVDEV_CPP}"; then
      sed -i '0,/^#include <fcntl.h>$/{s|^#include <fcntl.h>$|#include <linux/input-event-codes.h>\n#include <fcntl.h>|}' \
        "${EVDEV_CPP}"
    fi
  fi
}

makeinstall_target() {
export CXXFLAGS="`echo ${CXXFLAGS} | sed -e "s|-O.|-O3|g"`"
mkdir -p ${INSTALL}/usr/bin
cp -rf ${PKG_BUILD}/.${TARGET_NAME}/Binaries/dolphin-emu-nogui ${INSTALL}/usr/bin
cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

mkdir -p ${INSTALL}/usr/config/emuelec/configs/dolphin-emu
cp -rf ${PKG_BUILD}/Data/Sys/* ${INSTALL}/usr/config/emuelec/configs/dolphin-emu
cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/emuelec/configs/dolphin-emu

# Dolphin lê config em ${XDG_CONFIG_HOME}/dolphin-emu/Config/. O launcher
# seta XDG_CONFIG_HOME=/emuelec/configs e symlinka /storage/.local/share/
# dolphin-emu pra /emuelec/configs/dolphin-emu. Logo: copia o Dolphin.ini
# device-specifico pra Config/.
mkdir -p ${INSTALL}/usr/config/emuelec/configs/dolphin-emu/Config
DEVICE_CFG="${PKG_DIR}/config/${DEVICE}"
if [ -d "${DEVICE_CFG}" ]; then
  cp -rf ${DEVICE_CFG}/* ${INSTALL}/usr/config/emuelec/configs/dolphin-emu/Config/ || true
fi
}
