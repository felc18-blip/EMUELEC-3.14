PKG_NAME="aethersx2-sa"
PKG_VERSION="v1.5-3606"
PKG_ARCH="aarch64"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/RetroGFX/UnofficialOSAddOns"
PKG_DEPENDS_TARGET="toolchain qt5 libgpg-error fuse2 libXrandr"
PKG_LONGDESC="Arm PS2 Emulator appimage"
PKG_TOOLCHAIN="manual"

make_target() {
  :
}

makeinstall_target() {
  export STRIP=true

  APPIMAGE="${PKG_NAME}-${PKG_VERSION}.AppImage"
  URL="https://github.com/RetroGFX/UnofficialOSAddOns/raw/main/${APPIMAGE}"
  SOURCE_DIR="${ROOT}/sources/${PKG_NAME}"

  mkdir -p ${SOURCE_DIR}
  mkdir -p ${INSTALL}/usr/bin

  if [ ! -f "${SOURCE_DIR}/${APPIMAGE}" ]; then
    wget -O ${SOURCE_DIR}/${APPIMAGE} ${URL}
  fi

  cp ${SOURCE_DIR}/${APPIMAGE} ${INSTALL}/usr/bin/${PKG_NAME}
  chmod +x ${INSTALL}/usr/bin/${PKG_NAME}

  cp ${PKG_DIR}/scripts/start_aethersx2.sh \
     ${INSTALL}/usr/bin/start_aethersx2.sh

  sed -i "s/@APPIMAGE@/${PKG_NAME}/g" \
     ${INSTALL}/usr/bin/start_aethersx2.sh

  chmod +x ${INSTALL}/usr/bin/start_aethersx2.sh
}
