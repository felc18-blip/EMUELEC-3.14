# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="duckstation"
PKG_VERSION="fd3507c16d098fb32806c281caaefb205946da8a"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/stenzek/duckstation"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain SDL2 nasm:host ${OPENGLES} libevdev"
PKG_SECTION="libretro"
PKG_SHORTDESC="Fast PlayStation 1 emulator for x86-64/AArch32/AArch64 "
PKG_TOOLCHAIN="cmake"

# --- MODIFICAÇÃO PARA COMPATIBILIDADE ---
if [ "${DEVICE}" == "Amlogic-old" ]; then
    # Usamos variáveis separadas para não quebrar a string do CMake
    TARGET_CFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
    TARGET_CXXFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
fi
# ----------------------------------------

if [ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
	EXTRA_OPTS+=" -DUSE_DRMKMS=ON -DUSE_FBDEV=OFF -DUSE_MALI=OFF"
else
	EXTRA_OPTS+=" -DUSE_DRMKMS=OFF -DUSE_FBDEV=ON -DUSE_MALI=ON"
fi

pre_configure_target() {
    # 1. Patch para compatibilidade de Kernel Antigo (Substitui execveat por execve)
    # Procuramos em todo o código fonte para garantir que nenhuma lib interna use a syscall 293
    find ${PKG_BUILD} -type f -name "*.cpp" -o -name "*.h" | xargs sed -i 's/execveat/execve/g' 2>/dev/null || true

    PKG_CMAKE_OPTS_TARGET+=" -DANDROID=OFF \
                             -DENABLE_DISCORD_PRESENCE=OFF \
                             -DUSE_X11=OFF \
                             -DBUILD_LIBRETRO_CORE=OFF \
                             -DBUILD_GO2_FRONTEND=OFF \
                             -DBUILD_QT_FRONTEND=OFF \
                             -DBUILD_NOGUI_FRONTEND=ON \
                             -DCMAKE_BUILD_TYPE=Release \
                             -DBUILD_SHARED_LIBS=OFF \
                             -DUSE_SDL2=ON \
                             -DENABLE_CHEEVOS=ON \
                             -DHAVE_EGL=ON \
                             ${EXTRA_OPTS}"

    if [ "${DEVICE}" == "Amlogic-old" ]; then
        # Garante os headers de input para o Kernel 3.14
        cp -rf $(get_build_dir libevdev)/include/linux/linux/input-event-codes.h ${SYSROOT_PREFIX}/usr/include/linux/
    fi
}

post_make_target() {
if [ "${DEVICE}" == "Amlogic-old" ]; then
  rm ${SYSROOT_PREFIX}/usr/include/linux/input-event-codes.h
fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/bin/duckstation-nogui ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  
  mkdir -p ${INSTALL}/usr/config/emuelec/configs/duckstation
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/bin/* ${INSTALL}/usr/config/emuelec/configs/duckstation
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/emuelec/configs/duckstation
  rm -rf ${INSTALL}/usr/config/emuelec/configs/duckstation/database/gamecontrollerdb.txt
  ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt ${INSTALL}/usr/config/emuelec/configs/duckstation/database/gamecontrollerdb.txt
  
  rm -rf ${INSTALL}/usr/config/emuelec/configs/duckstation/duckstation-nogui
  rm -rf ${INSTALL}/usr/config/emuelec/configs/duckstation/common-tests
}