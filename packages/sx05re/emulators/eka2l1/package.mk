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
  -DEKA2L1_BUILD_TESTS=OFF
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  -DEKA2L1_BUILD_SDL2_FRONTEND=ON
"

pre_configure_target() {
  # --- 1. Seus Fixes Originais (Preservados) ---
  sed -i '/add_subdirectory(qt)/d' ${PKG_BUILD}/src/emu/CMakeLists.txt
  sed -i '/target_include_directories(buildvm/d' ${PKG_BUILD}/src/external/CMakeLists.txt
  sed -i '/add_subdirectory(programs)/d' ${PKG_BUILD}/src/external/mbedtls/CMakeLists.txt
  sed -i '/add_subdirectory(tests)/d' ${PKG_BUILD}/src/external/mbedtls/CMakeLists.txt
  sed -i '/add_library(mbedtls_test/,/)/d' ${PKG_BUILD}/src/external/mbedtls/CMakeLists.txt
  sed -i '/add_executable(mbedtls_test/,/)/d' ${PKG_BUILD}/src/external/mbedtls/CMakeLists.txt
  sed -i 's/-Werror//g' ${PKG_BUILD}/src/external/mbedtls/CMakeLists.txt
  sed -i 's/CMP0048 OLD/CMP0048 NEW/g' ${PKG_BUILD}/src/external/capstone/CMakeLists.txt
  sed -i '/target_include_directories(drivers/ s|)| ${CMAKE_SOURCE_DIR}/src/emu/common/include)|' ${PKG_BUILD}/src/emu/drivers/CMakeLists.txt
  sed -i '/find_package(Wayland/ s/^/#/' ${PKG_BUILD}/src/emu/drivers/CMakeLists.txt
  sed -i '/context_wayland.cpp/d' ${PKG_BUILD}/src/emu/drivers/CMakeLists.txt
  sed -i '/context_wayland.h/d' ${PKG_BUILD}/src/emu/drivers/CMakeLists.txt
  sed -i '/wayland/Id' ${PKG_BUILD}/src/emu/drivers/src/graphics/context.cpp
  sed -i 's/EGL_CONTEXT_MAJOR_VERSION/EGL_CONTEXT_MAJOR_VERSION_KHR/g' ${PKG_BUILD}/src/emu/drivers/src/graphics/backend/context_egl.cpp
  sed -i 's/EGL_CONTEXT_MINOR_VERSION/EGL_CONTEXT_MINOR_VERSION_KHR/g' ${PKG_BUILD}/src/emu/drivers/src/graphics/backend/context_egl.cpp
  sed -i '/precompile_headers/d' ${PKG_BUILD}/src/external/dynarmic/CMakeLists.txt
  sed -i '/cmake_pch/d' ${PKG_BUILD}/src/external/dynarmic/CMakeLists.txt
  sed -i 's/-Winvalid-offsetof//g' ${PKG_BUILD}/src/external/dynarmic/CMakeLists.txt

  # --- 2. Limpeza e Linkagem FFmpeg 8.1 ---
  rm -rf ${PKG_BUILD}/src/external/ffmpeg
  sed -i '/add_subdirectory(ffmpeg)/d' ${PKG_BUILD}/src/external/CMakeLists.txt
  sed -i '/external\/ffmpeg/d' ${PKG_BUILD}/src/emu/drivers/CMakeLists.txt
  sed -i '/external\/ffmpeg/d' ${PKG_BUILD}/src/emu/sdl2/CMakeLists.txt
  for f in libavformat.a libavcodec.a libswscale.a libavutil.a libswresample.a; do
    sed -i "s|\${CMAKE_SOURCE_DIR}/src/external/ffmpeg/linux/x86_64/lib/$f||g" ${PKG_BUILD}/src/emu/sdl2/CMakeLists.txt
  done
  sed -i '/cmake_minimum_required/a add_compile_options("-fpermissive")' ${PKG_BUILD}/CMakeLists.txt

  # --- 3. Header de Compatibilidade ---
cat > ${PKG_BUILD}/ffmpeg_compat.h << 'EOF'
#pragma once
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/channel_layout.h>
#include <libavutil/common.h>

#ifndef avcodec_close
#define avcodec_close(ctx) avcodec_free_context(&(ctx))
#endif

#define av_get_channel_layout_nb_channels(x) av_popcount64(x)

static inline SwrContext* swr_alloc_set_opts_compat(SwrContext* s, int64_t out_m, enum AVSampleFormat out_f, int out_r,
                                                   int64_t in_m, enum AVSampleFormat in_f, int in_r, int lo, void* lc) {
    AVChannelLayout out_l, in_l;
    av_channel_layout_from_mask(&out_l, out_m);
    av_channel_layout_from_mask(&in_l, in_m);
    SwrContext* res = s;
    swr_alloc_set_opts2(&res, &out_l, out_f, out_r, &in_l, in_f, in_r, lo, lc);
    return res;
}
#define swr_alloc_set_opts swr_alloc_set_opts_compat
EOF

  cp ${PKG_BUILD}/ffmpeg_compat.h ${PKG_BUILD}/src/emu/drivers/src/audio/backend/ffmpeg/
  cp ${PKG_BUILD}/ffmpeg_compat.h ${PKG_BUILD}/src/emu/drivers/src/video/backend/ffmpeg/

  # --- 4. Script Python Cirúrgico (Correção Final) ---
cat > ${PKG_BUILD}/ffmpeg_fix_v3.py << 'EOF'
import sys, re, os

def fix_file(path):
    with open(path, 'r') as f:
        content = f.read()

    # Injeta header
    if 'ffmpeg_compat.h' not in content:
        content = '#include "ffmpeg_compat.h"\n' + content

    # 1. Renomeia propriedades de lista (plurais)
    content = content.replace('channel_layouts', 'ch_layouts')

    # 2. Corrige declaração de ponteiros de iteradores (uint64_t* -> AVChannelLayout*)
    # Ex: const uint64_t *layout_support_layout = ...
    content = re.sub(r'const\s+(std::)?uint64_t\s*\*\s*([a-zA-Z0-9_]+)\s*=', r'const AVChannelLayout *\2 =', content)

    # 3. Corrige o acesso aos canais e loop para os iteradores transformados
    for v in ['p', 'layout_support_layout']:
        # Loop: while (*v) -> while (v && v->nb_channels > 0)
        content = re.sub(r'while\s*\(\s*\*' + v + r'\s*\)', f'while ({v} && {v}->nb_channels > 0)', content)
        # Extração de máscara: dest = *v -> dest = v->u.mask
        content = re.sub(r'=\s*\*' + v + r'\b', f'= {v}->u.mask', content)
        # Retorno: return *v -> return v->u.mask
        content = re.sub(r'return\s*\*' + v + r'\b', f'return {v}->u.mask', content)
        # Contagem de canais: av_...(*v) -> v->nb_channels
        content = re.sub(r'av_get_channel_layout_nb_channels\(\s*\*' + v + r'\s*\)', f'{v}->nb_channels', content)
        content = re.sub(r'av_popcount64\(\s*\*' + v + r'\s*\)', f'{v}->nb_channels', content)
        # Comparação: if (*v == ...)
        content = re.sub(r'\*' + v + r'\s*==', f'{v}->nb_channels ==', content)

    # 4. Corrige acesso a campos de structs (singular)
    # Apenas onde não for variável de classe (sem o _ no final)
    content = re.sub(r'(?<![a-zA-Z0-9_])channel_layout(?![a-zA-Z0-9_])', 'ch_layout.u.mask', content)
    content = re.sub(r'(?<![a-zA-Z0-9_])channels(?![a-zA-Z0-9_])', 'ch_layout.nb_channels', content)

    # 5. Fix específico para leitura de codec (linha 379/401)
    content = re.sub(r'av_get_channel_layout_nb_channels\(\*new_codec->ch_layouts\)', 'new_codec->ch_layouts->nb_channels', content)
    content = re.sub(r'av_popcount64\(\*new_codec->ch_layouts\)', 'new_codec->ch_layouts->nb_channels', content)

    with open(path, 'w') as f:
        f.write(content)

target_files = [
    'src/emu/drivers/src/audio/backend/ffmpeg/player_ffmpeg.cpp',
    'src/emu/drivers/src/audio/backend/ffmpeg/dsp_ffmpeg.cpp',
    'src/emu/drivers/src/video/backend/ffmpeg/video_player_ffmpeg.cpp'
]
for f in target_files:
    full_path = os.path.join(sys.argv[1], f)
    if os.path.exists(full_path):
        fix_file(full_path)
EOF

  python3 ${PKG_BUILD}/ffmpeg_fix_v3.py ${PKG_BUILD}

  # --- 5. Link Final ---
  sed -i '/target_link_libraries(eka2l1_sdl2/ s/)/ avformat avcodec avutil swscale swresample)/' ${PKG_BUILD}/src/emu/sdl2/CMakeLists.txt
  echo "// stub" > ${PKG_BUILD}/src/emu/drivers/src/graphics/backend/context_glx.cpp
  echo "// stub" > ${PKG_BUILD}/src/emu/drivers/src/graphics/backend/vulkan/graphics_vulkan.cpp
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
