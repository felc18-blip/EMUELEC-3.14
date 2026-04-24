# SPDX-License-Identifier: GPL-2.0-or-later
# Ship of Harkinian — Zelda OoT PC port, patched for Mali-450 (GLES 2.0)

PKG_NAME="soh"
PKG_VERSION="eeca7626d801991a516e805469a3f4629117121b"
PKG_LIBUS_VERSION="fdcaf6336776d24a6408d016b0a52243f108f250"
PKG_ZAPDTR_VERSION="ee3397a365c5f350a60538c88f0643f155944836"
PKG_OTREXP_VERSION="32e088e28c8cdd055d4bb8f3f219d33ad37963f3"
PKG_LICENSE="nonfree"
PKG_SITE="https://github.com/HarbourMasters/Shipwright"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="soh-${PKG_VERSION}.tar.gz"
PKG_ARCH="aarch64"
PKG_PRIORITY="optional"
PKG_SECTION="tools"
PKG_SHORTDESC="Ship of Harkinian — Zelda OoT PC port (Mali-450 ES2)"
PKG_LONGDESC="Ship of Harkinian port patched so the Fast3D rasterizer and ImGui emit OpenGL ES 2.0 shaders, compatible with Mali-450 Utgard."
PKG_TOOLCHAIN="cmake-make"

PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_net libzip libpng spdlog tinyxml2 \
                    nlohmann-json opusfile libvorbis opus zlib"

PKG_STB_SHA="0bc88af4de5fb022db643c2d8e549a0927749354"

PKG_CMAKE_OPTS_TARGET="-DCMAKE_BUILD_TYPE=Release \
                       -DUSE_OPENGLES=ON \
                       -DBUILD_REMOTE_CONTROL=OFF \
                       -DGENERATE_SOH_OTR=OFF \
                       -DSUPPRESS_WARNINGS=ON \
                       -DCMAKE_POLICY_VERSION_MINIMUM=3.5"

_fetch_submodule() {
  # $1=name, $2=sha, $3=url
  local name="$1" sha="$2" url="$3"
  local tarball="${SOURCES}/${PKG_NAME}/${name}-${sha}.tar.gz"
  mkdir -p "${SOURCES}/${PKG_NAME}"
  if [ ! -f "${tarball}" ]; then
    wget -O "${tarball}" "${url}/archive/${sha}.tar.gz"
  fi
  rm -rf "${PKG_BUILD}/${name}"
  mkdir -p "${PKG_BUILD}/${name}"
  tar xzf "${tarball}" -C "${PKG_BUILD}/${name}" --strip-components=1
}

pre_configure_target() {
  cd "${PKG_BUILD}"

  # GitHub tarball does not include submodules; fetch each separately
  _fetch_submodule libultraship "${PKG_LIBUS_VERSION}" \
    https://github.com/kenix3/libultraship
  _fetch_submodule ZAPDTR        "${PKG_ZAPDTR_VERSION}" \
    https://github.com/HarbourMasters/ZAPDTR
  _fetch_submodule OTRExporter   "${PKG_OTREXP_VERSION}" \
    https://github.com/HarbourMasters/OTRExporter

  # Apply Mali-450 GLES 2.0 patch inside libultraship (dir not named 'patches/'
  # to avoid the NextOS unpack stage auto-applying before the submodule exists)
  for p in "${PKG_DIR}/libus-patches/"*.patch; do
    [ -f "${p}" ] || continue
    ( cd libultraship && patch -p1 < "${p}" )
  done

  # CMake's file(DOWNLOAD) of stb_image.h can fail silently leaving a 0-byte
  # file; fetch to local cache and pass path to our patched common.cmake.
  local stb="${SOURCES}/${PKG_NAME}/stb_image-${PKG_STB_SHA}.h"
  if [ ! -s "${stb}" ]; then
    wget -O "${stb}" \
      "https://github.com/nothings/stb/raw/${PKG_STB_SHA}/stb_image.h"
  fi
  PKG_CMAKE_OPTS_TARGET+=" -DNEXTOS_STB_H=${stb}"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/local/bin
  cp ${PKG_BUILD}/soh/soh.elf ${INSTALL}/usr/local/bin/
  chmod +x ${INSTALL}/usr/local/bin/soh.elf
}
