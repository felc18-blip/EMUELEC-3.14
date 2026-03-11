################################################################################
# GameTank32 Libretro Core for EmuELEC (32-bit forced)
################################################################################

PKG_NAME="gametank32-lr"
PKG_VERSION="0.1.3"
PKG_SITE="https://github.com/RetroGFX/UnofficialOSAddOns"
PKG_URL="${PKG_SITE}/raw/refs/heads/main/cores/${PKG_NAME}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SHORTDESC="GameTank Libretro Core Written In Rust"
PKG_LONGDESC="The GameTank is an open source 8-bit retroconsole that YOU can build, and build games for"
PKG_TOOLCHAIN="manual"

unpack() {
  mkdir -p ${PKG_BUILD}
  cd ${PKG_BUILD}
  tar -xf ${SOURCES}/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.tar.xz
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro

  # Force 32b naming for EmuELEC
  cp ${PKG_BUILD}/*.so ${INSTALL}/usr/lib/libretro/gametank32_32b_libretro.so

  # Rename info file if present
  if ls ${PKG_BUILD}/*.info 1> /dev/null 2>&1; then
    cp ${PKG_BUILD}/*.info ${INSTALL}/usr/lib/libretro/gametank32_32b_libretro.info
  fi
}
