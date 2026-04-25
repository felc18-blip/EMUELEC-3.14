# SPDX-License-Identifier: GPL-2.0-or-later
#
# NextOS Elite Edition — NanoBoyAdvance standalone GBA emulator.
#
# Source: felc18-blip/NanoBoyAdvance-nextos (fork of nba-emu/NanoBoyAdvance
# at commit 3bb6f47, the same pin UnofficialOS uses). The NextOS-specific
# changes live as proper commits in the fork's `nextos` branch:
#
#   * Bus: rework DMA interleave (upstream backport, fixes Tales of Phantasia)
#   * platform/sdl: port SDL frontend renderer to GLES 2.0 (Mali-450)
#   * platform/sdl: hard-code EmuELEC config paths
#
# The Qt frontend is not built — it depends on desktop GL 3.3 + Qt6 which
# we do not ship for Amlogic-old.

PKG_NAME="nanoboyadvance-sa"
PKG_VERSION="9422ca0a6edfc935919d40280222113139f01b7a"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/felc18-blip/NanoBoyAdvance-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos"
PKG_OPEN_SOURCE_BIOS="https://github.com/Nebuleon/ReGBA/raw/master/bios/gba_bios.bin"
PKG_DEPENDS_TARGET="toolchain SDL2 ${OPENGLES}"
PKG_LONGDESC="NanoBoyAdvance: cycle-accurate Game Boy Advance emulator (NextOS, GLES2 SDL frontend)"
PKG_TOOLCHAIN="cmake"
PKG_SECTION="emuelec/emulators"

# Amlogic-old (kernel 3.14, Mali-450, Cortex-A53). Same toolchain quirks
# we use on duckstation/touchhle: ARMv8 syscall wrappers, no stack
# protector (libssp not always present in the cross-sysroot).
if [ "${DEVICE}" = "Amlogic-old" ]; then
  TARGET_CFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
  TARGET_CXXFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
fi

PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                         -DPLATFORM_SDL2=ON \
                         -DPLATFORM_QT=OFF \
                         -DCMAKE_BUILD_TYPE=Release"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/bin/sdl/NanoBoyAdvance ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  chmod 755 ${INSTALL}/usr/bin/*

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/nanoboyadvance
  cp -rf ${PKG_DIR}/config/config.toml ${INSTALL}/usr/config/emuelec/configs/nanoboyadvance/
  cp -rf ${PKG_DIR}/config/keymap.toml ${INSTALL}/usr/config/emuelec/configs/nanoboyadvance/
}
