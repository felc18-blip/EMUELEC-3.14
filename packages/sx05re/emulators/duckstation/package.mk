# SPDX-License-Identifier: GPL-2.0-or-later
#
# NextOS Elite Edition — DuckStation standalone PS1 emulator.
#
# Source: felc18-blip/duckstation-nextos (fork of stenzek/duckstation at
# commit fd3507c, Jul/2022 — the last DuckStation that builds against the
# Mali-400/450 libmali blob with the NoGUI frontend). The NextOS-specific
# build fixes (USE_MALI CMake option, hard-coded emuelec paths, higher
# MAX_NUM_BUTTONS) live as proper commits in the fork instead of runtime
# patches.

PKG_NAME="duckstation"
PKG_VERSION="aae997d6f30244caec46549c7f048c4d5cb2278b"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/felc18-blip/duckstation-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos"
PKG_DEPENDS_TARGET="toolchain SDL2 nasm:host ${OPENGLES} libevdev"
PKG_SECTION="emuelec/emulators"
PKG_SHORTDESC="Fast PlayStation 1 emulator (NoGUI frontend for Mali-450/fbdev)"
PKG_TOOLCHAIN="cmake"

# Amlogic-old kernel 3.14 compatibility flags. __LINUX_ARM_ARCH__=8 makes
# glibc pick the ARMv8 syscall wrappers that exist on this kernel; the
# -fno-stack-protector avoids needing libssp which the cross-sysroot does
# not always provide.
if [ "${DEVICE}" == "Amlogic-old" ]; then
  TARGET_CFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
  TARGET_CXXFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
fi

if [ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
  EXTRA_OPTS+=" -DUSE_DRMKMS=ON -DUSE_FBDEV=OFF -DUSE_MALI=OFF"
else
  EXTRA_OPTS+=" -DUSE_DRMKMS=OFF -DUSE_FBDEV=ON -DUSE_MALI=ON"
fi

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                           -DANDROID=OFF \
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
    # Kernel 3.14 doesn't ship linux/input-event-codes.h; libevdev does.
    # Temporarily expose that header in the sysroot so the duckstation
    # evdev backend compiles against up-to-date button codes.
    cp -rf $(get_build_dir libevdev)/include/linux/linux/input-event-codes.h \
      ${SYSROOT_PREFIX}/usr/include/linux/
  fi
}

post_make_target() {
  if [ "${DEVICE}" == "Amlogic-old" ]; then
    rm -f ${SYSROOT_PREFIX}/usr/include/linux/input-event-codes.h
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
  ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt \
    ${INSTALL}/usr/config/emuelec/configs/duckstation/database/gamecontrollerdb.txt

  rm -rf ${INSTALL}/usr/config/emuelec/configs/duckstation/duckstation-nogui
  rm -rf ${INSTALL}/usr/config/emuelec/configs/duckstation/common-tests
}
