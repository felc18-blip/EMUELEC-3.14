PKG_NAME="libplacebo"
PKG_VERSION="b2ea27dceb6418aabfe9121174c6dbb232942998"
PKG_LICENSE="LGPLv2.1"
PKG_SITE="https://code.videolan.org/videolan/libplacebo"
PKG_URL="https://github.com/haasn/libplacebo.git"

PKG_DEPENDS_TARGET="toolchain ffmpeg SDL2 luajit libass"
PKG_LONGDESC="Reusable library for GPU-accelerated image/video processing primitives and shaders"
PKG_TOOLCHAIN="meson"

if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" vulkan-loader vulkan-headers"
  PKG_MESON_OPTS_TARGET+=" -Dvulkan=enabled"
else
  PKG_MESON_OPTS_TARGET+=" -Dvulkan=disabled"
fi

post_unpack() {
  cd ${PKG_BUILD}
  git submodule update --init --recursive
}
