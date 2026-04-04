PKG_NAME="mpv"
PKG_VERSION="0.41.0"
PKG_LICENSE="GPLv2+"
PKG_SITE="https://mpv.io"
PKG_URL="https://github.com/mpv-player/mpv/archive/v${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="mpv-${PKG_VERSION}"
PKG_DEPENDS_TARGET="toolchain ffmpeg libass zlib SDL2 luajit libplacebo fribidi alsa-lib"
PKG_TOOLCHAIN="meson"

# Opções corrigidas para o MPV 0.41.0
# Na 0.41.0, o suporte a SDL2 é controlado por '-Dsdl-video' ou '-Dsdl-audio'
# mas se der erro, o mpv 0.41.0 simplificou para detecção automática ou nomes novos.
# Se as anteriores falharam, vamos usar as flags que não mudam:
# Opções corrigidas para o MPV 0.41.0
PKG_MESON_OPTS_TARGET="
  -Dcplayer=true
  -Dlibmpv=true
  -Dlua=luajit
  -Dalsa=enabled
  -Degl=enabled
  -Dsdl2-video=enabled
  -Dsdl2-audio=enabled
  -Diconv=enabled
  -Dpulse=disabled
  -Dpipewire=disabled
  -Djack=disabled
  -Ddrm=disabled
  -Dgl=disabled
  -Dwayland=disabled
  -Dx11=disabled
  -Dshaderc=disabled
  -Duchardet=disabled
  -Djavascript=disabled
"

pre_configure_target() {
  cd ${PKG_BUILD}
  
  echo ">>> Aplicando patch de compatibilidade IO para Kernel antigo..."
  if [ -f osdep/io.c ]; then
    sed -i 's/#define HAVE_MEMFD_CREATE 0/\/* #undef HAVE_MEMFD_CREATE *\//g' osdep/io.c
  fi

  # O TRUQUE: 
  # O script do EmuELEC vai tentar rodar o meson setup dentro da pasta atual.
  # Mas o Meson exige uma pasta separada. 
  # Alteramos a variável PKG_MESON_SCRIPT para apontar um nível acima, 
  # fazendo com que o diretório atual seja tratado como o diretório de BUILD 'limpo'.
  
  mkdir -p .aarch64-libreelec-linux-gnu
  cd .aarch64-libreelec-linux-gnu
  PKG_MESON_SCRIPT="../meson.build"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/lib

  BUILD_ARTIFACTS="${PKG_BUILD}/.aarch64-libreelec-linux-gnu"

  echo ">>> Instalando binários de: ${BUILD_ARTIFACTS}"

  # 1. Copia o Player (mpv)
  if [ -f "${BUILD_ARTIFACTS}/mpv" ]; then
    cp "${BUILD_ARTIFACTS}/mpv" "${INSTALL}/usr/bin/"
    ${STRIP} "${INSTALL}/usr/bin/mpv" 2>/dev/null || true
    echo ">>> mpv instalado com sucesso em /usr/bin"
  fi

  # 2. Copia a Biblioteca (libmpv)
  # O segredo: usamos 'find' com '-maxdepth 1 -type f -name' para ignorar as pastas .p
  echo ">>> Instalando bibliotecas libmpv..."
  find "${BUILD_ARTIFACTS}" -maxdepth 1 -type f -name "libmpv.so*" -exec cp -P {} "${INSTALL}/usr/lib/" \;
  find "${BUILD_ARTIFACTS}" -maxdepth 1 -type l -name "libmpv.so*" -exec cp -P {} "${INSTALL}/usr/lib/" \;

  # Opcional: Garante o strip nas libs que não são links simbólicos
  ${STRIP} ${INSTALL}/usr/lib/libmpv.so.2.5.0 2>/dev/null || true
}
