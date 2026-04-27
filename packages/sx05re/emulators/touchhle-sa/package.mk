# SPDX-License-Identifier: GPL-2.0-or-later
#
# NextOS Elite Edition — touchHLE iPhone OS high-level emulator.
#
# Source: upstream touchHLE/touchHLE pinned to a known-good commit.
# NextOS-specific tweaks live as in-tree patches under patches/:
#   000-set-paths.patch          - rootfs paths (/usr/lib, /storage/.config)
#   001-fix-app-picker.patch     - drop file-manager / website buttons
#   002-prefer-gles1-native.patch- skip GLES1OnGL2 fallback (Mali-450 has no
#                                  desktop GL 2.1; pure GLES 1.1 path only)
#
# Audio: SDL2 picks PulseAudio via sdl2-compat → SDL3, so we don't link
# libasound or pull sndio. Anything ALSA/sndio-related is dropped from
# the upstream ArchR recipe.

PKG_NAME="touchhle-sa"
PKG_LICENSE="MPLv2"
PKG_VERSION="d7668926268eded91545fa8ffae6590871ecf5b1"
PKG_SITE="https://github.com/touchHLE/touchHLE"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain cargo:host cargo rust SDL2 openal-soft"
PKG_LONGDESC="touchHLE: high-level emulator for iPhone OS apps (NextOS)"
PKG_TOOLCHAIN="manual"
PKG_SECTION="emuelec/emulators"

# Amlogic-old (kernel 3.14, Mali-450, Cortex-A53). Same toolchain quirks
# we use on duckstation: ARMv8 syscall wrappers, no stack protector
# (libssp not always present in the cross-sysroot).
if [ "${DEVICE}" = "Amlogic-old" ]; then
  TARGET_CFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
  TARGET_CXXFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
fi

make_target() {
  unset CMAKE
  # touchHLE's "static" feature (default) bundles SDL2 + openal-soft via
  # cmake-rs. The bundled SDL2 needs libsamplerate headers we don't ship,
  # and the bundled openal-soft hits a C++ standard mismatch with our
  # cross GCC. Use --no-default-features so sdl2-sys uses pkg-config and
  # the openal wrapper just links -lopenal from the sysroot.
  #
  # Rust 1.91+ requires -Zunstable-options to accept custom target triples
  # (aarch64-libreelec-linux-gnu is custom; the matching rustlib is built
  # by our rust:host package). Combine RUSTC_BOOTSTRAP=1 (needed to use
  # any -Z flag in stable rustc) + -Zunstable-options in RUSTFLAGS to let
  # cargo and downstream rustc invocations accept the custom triple.
  export RUSTC_BOOTSTRAP=1
  # LLVM 22.1.4 hits an internal assertion in vectorizer when compiling
  # ttf-parser with -C opt-level=3 (cargo's default for --release). Drop
  # to opt-level=2 to dodge the upstream LLVM bug.
  export RUSTFLAGS="-Zunstable-options -C opt-level=2 ${RUSTFLAGS}"
  cargo build \
    --target ${TARGET_NAME} \
    --release \
    --no-default-features
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/touchHLE ${INSTALL}/usr/bin

  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/lib/touchHLE/touchHLE_dylibs
  cp -rf ${PKG_BUILD}/touchHLE_dylibs/lib* ${INSTALL}/usr/lib/touchHLE/touchHLE_dylibs/

  mkdir -p ${INSTALL}/usr/lib/touchHLE/touchHLE_fonts
  cp -rf ${PKG_BUILD}/touchHLE_fonts/LiberationSans-* ${INSTALL}/usr/lib/touchHLE/touchHLE_fonts

  cp -rf ${PKG_BUILD}/touchHLE_default_options.txt ${INSTALL}/usr/lib/touchHLE/

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/touchHLE
  cp -rf ${PKG_BUILD}/touchHLE_options.txt ${INSTALL}/usr/config/emuelec/configs/touchHLE/

  chmod +x ${INSTALL}/usr/bin/touchHLE
  chmod +x ${INSTALL}/usr/bin/start_touchhle.sh
}
