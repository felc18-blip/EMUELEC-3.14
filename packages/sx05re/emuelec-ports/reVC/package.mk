# SPDX-License-Identifier: GPL-2.0-or-later
# reVC — GTA Vice City reverse-engineered, SDL2+GLES2 para Mali 400-series

PKG_NAME="reVC"
PKG_VERSION="f0cd06402c946ccbe5196925c56326cd9ba327de"
PKG_LIBRW_VERSION="81c9426cdde73717b04ae4dfc0f6c255f74a3a8a"
PKG_LICENSE="nonfree"
PKG_SITE="https://github.com/mrxenginner/reVC"
PKG_URL="https://github.com/mrxenginner/reVC/archive/${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="reVC-${PKG_VERSION}.tar.gz"
PKG_ARCH="aarch64"
PKG_PRIORITY="optional"
PKG_SECTION="tools"
PKG_SHORTDESC="reVC — GTA Vice City port (SDL2+GLES2)"
PKG_LONGDESC="reVC é a reimplementação open-source de GTA Vice City, buildada contra SDL2-compat + libMali GLES2 nativo. Mesmos fixes do re3 pro Mali 450 ES 2.0."
PKG_TOOLCHAIN="manual"

PKG_DEPENDS_TARGET="toolchain SDL2 openal-soft libsndfile mpg123"

pre_patch() {
  sed -i 's/\r$//' ${PKG_BUILD}/premake5.lua
}

make_target() {
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
    CPPFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -DLIBRW_FORCE_GLES -DLIBRW_SDL2 -DRW_GL3" \
    -j${CONCURRENCY_MAKE_LEVEL}

  # Copia librw.a pra dir arm64 (que reVC espera)
  mkdir -p "${PKG_BUILD}/vendor/librw/lib/linux-arm64-gl3/Release"
  cp "${PKG_BUILD}/vendor/librw/lib/linux-arm-gl3/Release/librw.a" \
     "${PKG_BUILD}/vendor/librw/lib/linux-arm64-gl3/Release/"

  # Volta pro PKG_BUILD
  cd "${PKG_BUILD}"

  # Cria GitSHA1.cpp dummy
  cat > "${PKG_BUILD}/src/extras/GitSHA1.cpp" << 'SHAEOF'
const char *g_GIT_SHA1 = "NextOS-Elite-Edition";
SHAEOF

  # Fix whole-archive — evita dead-strip de im2DRenderPrimitive do librw.a
  sed -i 's|\tlinks { "rw" }|\tlinkoptions { "-Wl,--whole-archive", "-l:librw.a", "-Wl,--no-whole-archive" }|' "${PKG_BUILD}/premake5.lua"

  # reVC só tem filter GLFW pra linux; adiciona plataforma e filter SDL2+GLES
  python3 <<PYEOF
path = "${PKG_BUILD}/premake5.lua"
with open(path, 'r') as f:
    src = f.read()

# 1) Adiciona a plataforma linux-arm64-librw_gl3_sdl2-oal na lista de platforms
plat_marker = '"linux-arm64-librw_gl3_sdl2-oal"'
if plat_marker not in src:
    plat_old = '\t\t\t"linux-arm64-librw_gl3_glfw-oal",\n\t\t}'
    plat_new = '\t\t\t"linux-arm64-librw_gl3_glfw-oal",\n\t\t\t"linux-arm64-librw_gl3_sdl2-oal",\n\t\t}'
    if plat_old in src:
        src = src.replace(plat_old, plat_new, 1)
        print("added linux-arm64 sdl2 platform")
    else:
        raise SystemExit("could not find linux arm64 platform anchor")

# 2) Troca filter que define RW_GL3 pra cobrir glfw E sdl2
old_rwgl3 = 'filter "platforms:*librw_gl3_glfw*"\n\t\tdefines { "RW_GL3" }'
new_rwgl3 = 'filter "platforms:*librw_gl3*"\n\t\tdefines { "RW_GL3" }'
if old_rwgl3 in src:
    src = src.replace(old_rwgl3, new_rwgl3, 1)
    print("widened RW_GL3 filter to match sdl2 too")

# 3) Adiciona defines RW_SDL2/LIBRW_SDL2 pro path sdl2 (como no windows)
marker_sdl2 = 'filter "platforms:*librw_gl3_sdl2*"'
if marker_sdl2 not in src:
    sdl2_block = '\n\tfilter "platforms:*librw_gl3_sdl2*"\n\t\tdefines { "RW_SDL2" }\n\t\tdefines { "LIBRW_SDL2" }\n'
    anchor = 'filter "platforms:*librw_gl3*"\n\t\tdefines { "RW_GL3" }'
    pos = src.find(anchor)
    if pos >= 0:
        insert_at = src.find('\n', pos + len(anchor)) + 1
        src = src[:insert_at] + sdl2_block + src[insert_at:]
        print("added sdl2 defines block")

# 4) Adiciona filter de link pra linux+sdl2
marker = 'filter "platforms:linux*gl3_sdl2*"'
if marker not in src:
    old = '\tfilter "platforms:linux*gl3_glfw*"\n\t\tlinks { "GL", "glfw" }\n'
    new = old + '\n\tfilter "platforms:linux*gl3_sdl2*"\n\t\tlinks { "EGL", "GLESv2", "SDL2" }\n'
    if old in src:
        src = src.replace(old, new, 1)
        print("added linux+sdl2 links filter")
    else:
        raise SystemExit("could not find linux+glfw filter anchor")

with open(path, 'w') as f:
    f.write(src)
PYEOF

  # Fix 2D depth test no fake.cpp — mesmo wrapper do re3
  if [ -f "${PKG_BUILD}/src/fakerw/fake.cpp" ]; then
    sed -i 's|{ im2d::RenderPrimitive((PrimitiveType)primType, vertices, numVertices); return true; }|{ rw::SetRenderState(rw::ZTESTENABLE, 0); rw::SetRenderState(rw::ZWRITEENABLE, 0); im2d::RenderPrimitive((PrimitiveType)primType, vertices, numVertices); rw::SetRenderState(rw::ZTESTENABLE, 1); rw::SetRenderState(rw::ZWRITEENABLE, 1); return true; }|' "${PKG_BUILD}/src/fakerw/fake.cpp"
    sed -i 's|{ im2d::RenderIndexedPrimitive((PrimitiveType)primType, vertices, numVertices, indices, numIndices); return true; }|{ rw::SetRenderState(rw::ZTESTENABLE, 0); rw::SetRenderState(rw::ZWRITEENABLE, 0); im2d::RenderIndexedPrimitive((PrimitiveType)primType, vertices, numVertices, indices, numIndices); rw::SetRenderState(rw::ZTESTENABLE, 1); rw::SetRenderState(rw::ZWRITEENABLE, 1); return true; }|' "${PKG_BUILD}/src/fakerw/fake.cpp"
  fi

  # reVC
  /usr/bin/premake5 gmake
  make -C build config=release_linux-arm64-librw_gl3_sdl2-oal \
    CPPFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -DLIBRW_FORCE_GLES -DLIBRW_SDL2 -DRW_GL3" \
    -j${CONCURRENCY_MAKE_LEVEL}
}

makeinstall_target() {
  cd "${PKG_BUILD}"
  mkdir -p ${INSTALL}/usr/bin
  # Binário pode se chamar reVC ou reVC (case), tenta ambos
  if [ -f bin/linux-arm64-librw_gl3_sdl2-oal/Release/reVC ]; then
    cp bin/linux-arm64-librw_gl3_sdl2-oal/Release/reVC ${INSTALL}/usr/bin/reVC
  elif [ -f bin/linux-arm64-librw_gl3_sdl2-oal/Release/reVC.elf ]; then
    cp bin/linux-arm64-librw_gl3_sdl2-oal/Release/reVC.elf ${INSTALL}/usr/bin/reVC
  fi
}
