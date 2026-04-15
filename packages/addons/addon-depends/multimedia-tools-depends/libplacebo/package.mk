# SPDX-License-Identifier: GPL-2.0-only
# NextOS-Elite-Edition: Felipe - libplacebo (Fix para mpv 0.41.0)

PKG_NAME="libplacebo"
PKG_VERSION="b2ea27dceb6418aabfe9121174c6dbb232942998"
PKG_LICENSE="LGPLv2.1"
PKG_SITE="https://code.videolan.org/videolan/libplacebo"
PKG_URL="https://github.com/haasn/libplacebo.git"

# Adicionado glad e jinja2 porque o libplacebo moderno não compila sem eles
PKG_DEPENDS_TARGET="toolchain ffmpeg SDL2 luajit libass glad:host Jinja2:host"
PKG_DEPENDS_UNPACK="vulkan-headers"
PKG_LONGDESC="Reusable library for GPU-accelerated image/video processing primitives and shaders"
PKG_TOOLCHAIN="meson"

# Forçamos estático para performance na Mali-450
PKG_MESON_OPTS_TARGET="-Ddefault_library=static \
                       -Dprefer_static=true \
                       -Dvulkan=disabled \
                       -Dopengl=enabled \
                       -Ddemos=false"

post_unpack() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive
}

pre_configure_target() {
  # Isso evita erros de compilação por falta de definições de structs
  export TARGET_CFLAGS="${TARGET_CFLAGS} -I$(get_build_dir vulkan-headers)/include"
}

post_makeinstall_target() {
  local PC_FILE="${INSTALL}/usr/lib/pkgconfig/libplacebo.pc"

  if [ -f "${PC_FILE}" ]; then
    echo ">>> Ajustando libplacebo.pc para GCC 15 e Linkagem Estática..."

    # Resolve o problema de include (colorspace.h)
    sed -i "s|Cflags:.*|Cflags: -I\${includedir}|" "${PC_FILE}"

    # O SEGREDO: Em linkagem estática, precisamos de 'Libs.private'
    # Adicionamos -lstdc++ e -lMali de forma que o MPV seja forçado a carregar o runtime do C++
    sed -i '/^Libs:/ s/$/ -lstdc++ -lm -lMali/' "${PC_FILE}"

    # Adiciona explicitamente ao Cflags que o código que usa essa lib deve entender C++ moderno se necessário
    sed -i '/^Cflags:/ s/$/ -std=c++17/' "${PC_FILE}"
  fi
}
