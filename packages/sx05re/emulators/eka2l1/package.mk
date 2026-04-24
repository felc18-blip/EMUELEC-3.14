# SPDX-License-Identifier: GPL-2.0
PKG_NAME="eka2l1"
PKG_VERSION="d2e7abb191bf41ffa1413100154590e0930aebfa"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/AveyondFly/EKA2L1"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="master"
PKG_GIT_SUBMODULES="yes"
PKG_DEPENDS_TARGET="toolchain SDL2 freetype zlib"
PKG_SECTION="emuelec/emulators"
PKG_SHORTDESC="Symbian OS / N-Gage emulator for aarch64 Linux"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="-lto"

PKG_CMAKE_OPTS_TARGET="
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  -DEKA2L1_BUILD_TESTS=OFF
  -DENABLE_TESTING=OFF
  -DENABLE_PROGRAMS=OFF
  -DEKA2L1_BUILD_SDL2_FRONTEND=ON
"

pre_configure_target() {
  # GCC 15 promove vários warnings antigos a errors; ignoramos os que afetam
  # subprojects (mbedtls tests etc) e mantemos o restante do build limpo.
  export CFLAGS="${CFLAGS} -Wno-error=unterminated-string-initialization -Wno-error=calloc-transposed-args -Wno-error"
  export CXXFLAGS="${CXXFLAGS} -Wno-error=unterminated-string-initialization -Wno-error=calloc-transposed-args -Wno-error"

  # Disable subprojects que não compilam ou não usamos
  sed -i '/add_subdirectory(qt)/d' ${PKG_BUILD}/src/emu/CMakeLists.txt
  sed -i '/target_include_directories(buildvm/d' ${PKG_BUILD}/src/external/CMakeLists.txt
  sed -i '/add_subdirectory(programs)/d' ${PKG_BUILD}/src/external/mbedtls/CMakeLists.txt
  sed -i '/add_subdirectory(tests)/d' ${PKG_BUILD}/src/external/mbedtls/CMakeLists.txt

  # Stub backends de display/render que não usamos (sem X11, sem Vulkan, sem Wayland)
  echo "// stub" > ${PKG_BUILD}/src/emu/drivers/src/graphics/backend/context_glx.cpp
  echo "// stub" > ${PKG_BUILD}/src/emu/drivers/src/graphics/backend/vulkan/graphics_vulkan.cpp
  echo "// stub" > ${PKG_BUILD}/src/emu/drivers/src/graphics/backend/context_wayland.cpp

  # Aplica patches da pasta patches/ (NextOS: no-X11/no-Wayland + cmake 4.x)
  for p in "${PKG_DIR}/patches/"*.patch; do
    [ -f "$p" ] || continue
    ( cd "${PKG_BUILD}" && patch -p1 < "$p" || true )
  done

  # NextOS: ffmpeg 8.x compat — AVPacket virou opaco, não pode mais alocar como
  # struct. Trocar packet_ por ponteiro e av_init_packet por av_packet_alloc.
  PFH="${PKG_BUILD}/src/emu/drivers/include/drivers/audio/backend/ffmpeg/player_ffmpeg.h"
  PFC="${PKG_BUILD}/src/emu/drivers/src/audio/backend/ffmpeg/player_ffmpeg.cpp"
  sed -i 's|^        AVPacket packet_;|        AVPacket *packet_;|' "${PFH}"
  sed -i 's|av_read_frame(format_context_, &packet_)|av_read_frame(format_context_, packet_)|g' "${PFC}"
  sed -i 's|avcodec_send_packet(codec_, &packet_)|avcodec_send_packet(codec_, packet_)|g' "${PFC}"
  sed -i 's|av_packet_unref(&packet_)|av_packet_unref(packet_)|g' "${PFC}"
  sed -i 's|av_init_packet(&packet_);|packet_ = av_packet_alloc();|g' "${PFC}"

  # NextOS: ffmpeg 8.x removeu avcodec_close, swr_alloc_set_opts (sem 2),
  # av_get_channel_layout_nb_channels. Cria shim wrapper que mapeia pra API moderna.
  SHIM_DIR="${PKG_BUILD}/src/emu/drivers/include/drivers/audio/backend/ffmpeg"
  cat > "${SHIM_DIR}/nextos_ffmpeg8_shim.h" << 'SHIMEOF'
#pragma once
extern "C" {
#include <libavcodec/avcodec.h>
#include <libavutil/channel_layout.h>
#include <libswresample/swresample.h>
}
/* avcodec_close foi removido; avcodec_free_context faz o trabalho equivalente. */
static inline int avcodec_close(AVCodecContext *ctx) {
    if (ctx) avcodec_free_context(&ctx);
    return 0;
}
/* swr_alloc_set_opts (sem 2) removido; reimplementar via swr_alloc_set_opts2. */
static inline struct SwrContext *swr_alloc_set_opts(
        struct SwrContext *s, int64_t out_layout, enum AVSampleFormat out_fmt, int out_rate,
        int64_t in_layout, enum AVSampleFormat in_fmt, int in_rate, int log_offset, void *log_ctx) {
    AVChannelLayout out_ch, in_ch;
    av_channel_layout_from_mask(&out_ch, (uint64_t)out_layout);
    av_channel_layout_from_mask(&in_ch, (uint64_t)in_layout);
    int err = swr_alloc_set_opts2(&s, &out_ch, out_fmt, out_rate, &in_ch, in_fmt, in_rate, log_offset, log_ctx);
    av_channel_layout_uninit(&out_ch);
    av_channel_layout_uninit(&in_ch);
    return err < 0 ? NULL : s;
}
/* av_get_channel_layout_nb_channels removido; equivalente via AVChannelLayout. */
static inline int av_get_channel_layout_nb_channels(uint64_t layout) {
    AVChannelLayout ch; av_channel_layout_from_mask(&ch, layout);
    int n = ch.nb_channels;
    av_channel_layout_uninit(&ch);
    return n;
}
SHIMEOF
  # Injeta o shim em todos os .cpp do path ffmpeg do drivers
  for f in "${PKG_BUILD}/src/emu/drivers/src/audio/backend/ffmpeg/"*.cpp \
           "${PKG_BUILD}/src/emu/drivers/src/video/backend/ffmpeg/"*.cpp; do
    [ -f "$f" ] || continue
    grep -q "nextos_ffmpeg8_shim.h" "$f" || \
      sed -i '1i #include "drivers/audio/backend/ffmpeg/nextos_ffmpeg8_shim.h"' "$f"
  done

  # NextOS: libMali EGL 1.4 só expõe versões _KHR; eka2l1 usa nomes core EGL 1.5
  CTX_EGL="${PKG_BUILD}/src/emu/drivers/src/graphics/backend/context_egl.cpp"
  sed -i 's|EGL_CONTEXT_MAJOR_VERSION\b|EGL_CONTEXT_MAJOR_VERSION_KHR|g' "${CTX_EGL}"
  sed -i 's|EGL_CONTEXT_MINOR_VERSION\b|EGL_CONTEXT_MINOR_VERSION_KHR|g' "${CTX_EGL}"
  # Reverter caso o sed bata duas vezes (X_KHR_KHR)
  sed -i 's|_KHR_KHR|_KHR|g' "${CTX_EGL}"

  cat > ${PKG_BUILD}/src/external/ffmpeg/CMakeLists.txt << 'EOF'
if (NOT DEFINED FFMPEG_CORE_NAME)
    set(FFMPEG_CORE_NAME ffmpeg)
endif()
add_library(${FFMPEG_CORE_NAME} INTERFACE)
# NextOS: NÃO incluir headers do submodule (são do ffmpeg 4.x, conflitam com a
# lib do sistema que é 8.x). Usa headers do sysroot (vêm do CMAKE_SYSROOT).
target_link_libraries(${FFMPEG_CORE_NAME} INTERFACE avformat avcodec avutil swscale swresample z)
EOF
}

make_target() {
  BUILD_DIR="${PKG_BUILD}/.aarch64-libreelec-linux-gnu"
  LUAJIT_SRC="${PKG_BUILD}/src/external/luajit/src"
  LUAJIT_CMAKE_BUILD="${BUILD_DIR}/src/external/luajit-cmake"
  MINILUA_BIN="${LUAJIT_CMAKE_BUILD}/minilua/minilua"
  BUILDVM_BIN="${LUAJIT_CMAKE_BUILD}/buildvm/buildvm"

  cd "${BUILD_DIR}"

  ninja minilua || true
  gcc "${LUAJIT_SRC}/host/minilua.c" -o "${MINILUA_BIN}" -lm
  ninja -t restat

  ninja buildvm || true
  gcc \
    -I"${LUAJIT_SRC}" \
    -I"${LUAJIT_CMAKE_BUILD}" \
    -DLUAJIT_TARGET=LUAJIT_ARCH_arm64 \
    -DLJ_ARCH_HASFPU=1 \
    -DLJ_ABI_SOFTFP=0 \
    -DLUAJIT_NUMMODE=2 \
    "${LUAJIT_SRC}/host/buildvm.c" \
    "${LUAJIT_SRC}/host/buildvm_asm.c" \
    "${LUAJIT_SRC}/host/buildvm_fold.c" \
    "${LUAJIT_SRC}/host/buildvm_lib.c" \
    "${LUAJIT_SRC}/host/buildvm_peobj.c" \
    -o "${BUILDVM_BIN}" -lm
  ninja -t restat

  ninja ${NINJA_OPTS} ${PKG_MAKE_OPTS_TARGET}
}

makeinstall_target() {
  BUILD_DIR="${PKG_BUILD}/.aarch64-libreelec-linux-gnu"

  mkdir -p "${INSTALL}/usr/bin/eka2l1"
  cp -a "${BUILD_DIR}/bin/." "${INSTALL}/usr/bin/eka2l1/"
  chmod +x "${INSTALL}/usr/bin/eka2l1/eka2l1_sdl2"

  cp "${PKG_DIR}/scripts/ekastart.sh" "${INSTALL}/usr/bin/ekastart.sh"
  chmod +x "${INSTALL}/usr/bin/ekastart.sh"

  mkdir -p "${INSTALL}/usr/config/emuelec/configs/eka2l1/gptk"
  cp -f "${PKG_DIR}/config/eka.gptk" "${INSTALL}/usr/config/emuelec/configs/eka2l1/gptk/eka.gptk"
}