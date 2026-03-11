################################################################################
#      Yaba Sanshiro Libretro - Otimizado para Amlogic-old (S905L)
################################################################################

PKG_NAME="yabasanshiro-lr"
PKG_VERSION="d2afc930613744ee7bea600bde8c9558f68dba60"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/yabause"
# Usando link direto para evitar erros de GIT pathspec
PKG_URL="https://github.com/libretro/yabause/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="Port of YabaSanshiro to libretro (GLES2 + S905L)."
PKG_LONGDESC="Port of YabaSanshiro to libretro for Mali-450 devices."
PKG_TOOLCHAIN="make"

pre_configure_target() {
  # 1. Localiza o Makefile (pode estar em libretro/ ou yabause/src/libretro/)
  local MAKE_PATH=$(find "${PKG_BUILD}" -name "Makefile" | grep "libretro" | head -n 1)

  if [ -z "$MAKE_PATH" ]; then
    echo "ERRO: Makefile não encontrado! Verificando estrutura de pastas..."
    ls -R "${PKG_BUILD}" | head -n 20
    return 1
  fi

  echo "Makefile encontrado em: $MAKE_PATH"
  local MAKE_DIR=$(dirname "$MAKE_PATH")

  # 2. LIMPEZA E SUPORTE OPENGL ES 2.0 (Mali-450)
  # Remove flags de PC e GLES3 que travam o build
  sed -i 's/-mfpmath=sse//g' "$MAKE_PATH"
  sed -i 's/-lGL//g' "$MAKE_PATH"
  sed -i 's/HAVE_OPENGL/HAVE_OPENGLES/g' "$MAKE_PATH"
  sed -i 's/FORCE_GLES3 = 1/FORCE_GLES3 = 0/g' "$MAKE_PATH"
  sed -i 's/HAVE_OPENGLES3 = 1/HAVE_OPENGLES3 = 0/g' "$MAKE_PATH"
  sed -i 's/glsym_es3.c/glsym_es2.c/g' "$MAKE_PATH"
  
  # 3. CORREÇÃO DE HEADERS (GL/gl.h -> GLES2/gl2.h)
  find "${PKG_BUILD}" -name "rglgen_headers.h" -exec sed -i 's/<GL\/gl.h>/<GLES2\/gl2.h>/g' {} +
  find "${PKG_BUILD}" -name "rglgen_headers.h" -exec sed -i 's/<GL\/glext.h>/<GLES2\/gl2ext.h>/g' {} +

  # 4. FORÇA CÓDIGO GLES2 (Desativa recursos de 64-bit modernos na parte de vídeo)
  find "${PKG_BUILD}" -type f \( -name "*.h" -o -name "*.c" -o -name "*.cpp" \) -exec sed -i 's/defined(__aarch64__)/0/g' {} +
  find "${PKG_BUILD}" -type f \( -name "*.h" -o -name "*.c" -o -name "*.cpp" \) -exec sed -i 's/defined(HAVE_OPENGLES3)/0/g' {} +

  # 5. CONFIGURAÇÃO DO MAKE (Dynarec rápido + GLES 2.0)
  PKG_MAKE_OPTS_TARGET+=" -C ${MAKE_DIR} platform=unix FORCE_GLES=1 HAVE_OPENGLES=1 HAVE_OPENGLES3=0"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  # Busca o .so gerado independente do nome
  local OUT_FILE=$(find "${PKG_BUILD}" -name "*yaba*_libretro.so" | head -n 1)
  if [ -f "$OUT_FILE" ]; then
    cp "$OUT_FILE" "${INSTALL}/usr/lib/libretro/yabasanshiro-lr_libretro.so"
  else
    echo "ERRO: Arquivo .so não foi gerado!"
    return 1
  fi
}