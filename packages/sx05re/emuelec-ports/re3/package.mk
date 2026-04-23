# SPDX-License-Identifier: GPL-2.0-or-later
# re3 — GTA III reverse-engineered, SDL2+GLES2 para Mali 400-series

PKG_NAME="re3"
PKG_VERSION="ead2747eadbbdbf0e134eea6679364153dd6c4b8"
PKG_LIBRW_VERSION="81c9426cdde73717b04ae4dfc0f6c255f74a3a8a"
PKG_LICENSE="nonfree"
PKG_SITE="https://github.com/nosro1/re3"
PKG_URL="https://github.com/nosro1/re3/archive/${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="re3-${PKG_VERSION}.tar.gz"
PKG_ARCH="aarch64"
PKG_PRIORITY="optional"
PKG_SECTION="tools"
PKG_SHORTDESC="re3 — GTA III port (SDL2+GLES2)"
PKG_LONGDESC="re3 é a reimplementação open-source de GTA III, buildada contra SDL2-compat + libMali GLES2 nativo."
PKG_TOOLCHAIN="manual"

PKG_DEPENDS_TARGET="toolchain SDL2 openal-soft libsndfile mpg123"

pre_patch() {
  sed -i 's/\r$//' ${PKG_BUILD}/premake5.lua
}

make_target() {
  # PKG_BUILD é o raiz com src/ + premake5.lua
  cd "${PKG_BUILD}"

  # Baixa librw se não estiver em cache
  if [ ! -f "${SOURCES}/${PKG_NAME}/librw-${PKG_LIBRW_VERSION}.tar.gz" ]; then
    mkdir -p "${SOURCES}/${PKG_NAME}"
    wget -O "${SOURCES}/${PKG_NAME}/librw-${PKG_LIBRW_VERSION}.tar.gz" \
      "https://github.com/nosro1/librw/archive/${PKG_LIBRW_VERSION}.tar.gz"
  fi

  # Descompacta librw em vendor/
  rm -rf "${PKG_BUILD}/vendor/librw"
  mkdir -p "${PKG_BUILD}/vendor/librw"
  tar xzf "${SOURCES}/${PKG_NAME}/librw-${PKG_LIBRW_VERSION}.tar.gz" \
    -C "${PKG_BUILD}/vendor/librw" --strip-components=1

  # Normaliza line endings
  find "${PKG_BUILD}/vendor/librw" -type f \( -name "*.lua" -o -name "*.cpp" -o -name "*.h" \) \
    -exec sed -i 's/\r$//' {} \; 2>/dev/null || true

  # Aplica todos patches da pasta librw-patches/ (dentro do vendor/librw)
  for p in "${PKG_DIR}/librw-patches/"*.patch; do
    [ -f "$p" ] || continue
    ( cd "${PKG_BUILD}/vendor/librw" && patch -p1 < "$p" || true )
  done

  # Patch direto nos arquivos .inc pré-gerados (MAX_LIGHTS 8 -> 4)
  find "${PKG_BUILD}/vendor/librw/src/gl/shaders" -name "*.inc" \
    -exec sed -i 's/MAX_LIGHTS 8/MAX_LIGHTS 4/g' {} \;

  # Remove /usr/include hardcoded dos premake5.lua (cross-compile safety)
  find "${PKG_BUILD}" -name "premake5.lua" \
    -exec sed -i '/includedirs.*"\/usr\/include/d' {} \;

  # librw primeiro (buildado como arm)
  cd "${PKG_BUILD}/vendor/librw"
  /usr/bin/premake5 gmake --gfxlib=sdl2
  make -C build librw config=release_linux-arm-gl3 \
    CPPFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -DLIBRW_FORCE_GLES" \
    -j${CONCURRENCY_MAKE_LEVEL}

  # Copia librw.a pra dir arm64 (que re3 espera)
  mkdir -p "${PKG_BUILD}/vendor/librw/lib/linux-arm64-gl3/Release"
  cp "${PKG_BUILD}/vendor/librw/lib/linux-arm-gl3/Release/librw.a" \
     "${PKG_BUILD}/vendor/librw/lib/linux-arm64-gl3/Release/"

  # Volta pro PKG_BUILD pra buildar re3
  cd "${PKG_BUILD}"

  # Cria GitSHA1.cpp dummy
  cat > "${PKG_BUILD}/src/extras/GitSHA1.cpp" << 'SHAEOF'
const char *g_GIT_SHA1 = "NextOS-Elite-Edition";
SHAEOF

  # Fix whole-archive — evita dead-strip de im2DRenderPrimitive do librw.a
  sed -i 's|\tlinks { "rw" }|\tlinkoptions { "-Wl,--whole-archive", "-l:librw.a", "-Wl,--no-whole-archive" }|' "${PKG_BUILD}/premake5.lua"

  # Fix GL -> GLESv2 + EGL (libMali não tem libGL desktop, só GLES)
  sed -i 's|links { "GL", "SDL2" }|links { "GLESv2", "EGL", "SDL2" }|' "${PKG_BUILD}/premake5.lua"

  # Fix 2D depth test — envolve im2D com disable/enable via rw::SetRenderState
  # Isso garante que o menu 2D não seja descartado por depth test (Mali 450)
  sed -i 's|{ im2d::RenderPrimitive((PrimitiveType)primType, vertices, numVertices); return true; }|{ rw::SetRenderState(rw::ZTESTENABLE, 0); rw::SetRenderState(rw::ZWRITEENABLE, 0); im2d::RenderPrimitive((PrimitiveType)primType, vertices, numVertices); rw::SetRenderState(rw::ZTESTENABLE, 1); rw::SetRenderState(rw::ZWRITEENABLE, 1); return true; }|' "${PKG_BUILD}/src/fakerw/fake.cpp"

  sed -i 's|{ im2d::RenderIndexedPrimitive((PrimitiveType)primType, vertices, numVertices, indices, numIndices); return true; }|{ rw::SetRenderState(rw::ZTESTENABLE, 0); rw::SetRenderState(rw::ZWRITEENABLE, 0); im2d::RenderIndexedPrimitive((PrimitiveType)primType, vertices, numVertices, indices, numIndices); rw::SetRenderState(rw::ZTESTENABLE, 1); rw::SetRenderState(rw::ZWRITEENABLE, 1); return true; }|' "${PKG_BUILD}/src/fakerw/fake.cpp"

  # re3
  /usr/bin/premake5 gmake
  make -C build config=release_linux-arm64-librw_gl3_sdl2-oal \
    CPPFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -DLIBRW_FORCE_GLES" \
    -j${CONCURRENCY_MAKE_LEVEL}
}

makeinstall_target() {
  cd "${PKG_BUILD}"
  mkdir -p ${INSTALL}/usr/bin
  cp bin/linux-arm64-librw_gl3_sdl2-oal/Release/re3 ${INSTALL}/usr/bin/re3
}
