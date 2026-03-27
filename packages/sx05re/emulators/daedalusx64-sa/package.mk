# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present ArchR

PKG_NAME="daedalusx64-sa"
PKG_VERSION="f17e9ed86f3806fadeb69abd29c9526ab2d4bd1b"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/DaedalusX64/daedalus"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain libfmt SDL2 SDL2_ttf glm"
PKG_LONGDESC="DaedalusX64 Nintendo 64 emulator"

if [ "${OPENGL_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL}"
elif [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

post_unpack() {
  cd ${PKG_BUILD}
  rm -rf SaveStates .gitmodules
  git clone --depth 1 https://github.com/DaedalusX64/savestates SaveStates

  # 1. Patch GLES nos headers
  find . -type f \( -name "*.h" -o -name "*.cpp" -o -name "*.inl" \) -exec sed -i 's|<GL/gl.h>|<GLES2/gl2.h>\n#include <GLES2/gl2ext.h>|g' {} +
  find . -type f \( -name "*.h" -o -name "*.cpp" -o -name "*.inl" \) -exec sed -i 's|<GL/glew.h>|<GLES2/gl2.h>\n#include <GLES2/gl2ext.h>|g' {} +

  # 2. Hack de VAO: Trocar para OES
  find . -type f \( -name "*.h" -o -name "*.cpp" \) -exec sed -i 's/glGenVertexArrays/glGenVertexArraysOES/g' {} +
  find . -type f \( -name "*.h" -o -name "*.cpp" \) -exec sed -i 's/glBindVertexArray/glBindVertexArrayOES/g' {} +
  find . -type f \( -name "*.h" -o -name "*.cpp" \) -exec sed -i 's/glDeleteVertexArrays/glDeleteVertexArraysOES/g' {} +

  # Injeção de protótipos manuais (Garante que o compilador não reclame da falta de declaração)
  if [ -f Source/SysGLES/HLEGraphics/RendererGL.cpp ]; then
    sed -i '1i extern "C" { void glGenVertexArraysOES(int n, unsigned int *arrays); void glBindVertexArrayOES(unsigned int array); void glDeleteVertexArraysOES(int n, const unsigned int *arrays); }' Source/SysGLES/HLEGraphics/RendererGL.cpp
  fi

  # 3. Limpeza de CMake
  find . -name "CMakeLists.txt" -exec sed -i 's/OpenGL::GL/GLESv2 EGL/g' {} +
  sed -i 's/find_package(OpenGL REQUIRED)//g' Source/CMakeLists.txt
  
  # 4. Forçar AARCH64 e Dynarec
  sed -i 's/x86_64 Detected/aarch64 Detected/g' Source/CMakeLists.txt
  sed -i '/project(DaedalusX64)/a set(AARCH64 ON)\nset(ARM64 ON)\nset(DAEDALUS_ENABLE_DYNAREC ON)\nset(DAEDALUS_64BIT ON)' Source/CMakeLists.txt
}

make_target() {
  cd ${PKG_BUILD}
  mkdir -p build && cd build

  cmake .. \
    ${TARGET_CMAKE_OPTS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DDAEDALUS_GLES=ON \
    -DDAEDALUS_GL=OFF \
    -DAARCH64=ON \
    -DARM64=ON \
    -DDAEDALUS_64BIT=ON \
    -DDAEDALUS_ENABLE_DYNAREC=ON \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS} -DGL_GLEXT_PROTOTYPES -DDAEDALUS_GLES -DDAEDALUS_64BIT" \
    -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS} -lGLESv2 -lEGL"

  make -j$(nproc)
}

makeinstall_target() {
  if [ "${ARCH}" = "aarch64" ]; then
    # 1. Cria a estrutura e tenta pegar os dados da versão ARM (32 bits) se existir
    mkdir -p ${INSTALL}/usr
    if [ -d "${ROOT}/build.${DISTRO}-${DEVICE}.arm/install_pkg/daedalusx64-sa-${PKG_VERSION}/usr" ]; then
       echo "Copiando assets da versão ARM32..."
       cp -r ${ROOT}/build.${DISTRO}-${DEVICE}.arm/install_pkg/daedalusx64-sa-${PKG_VERSION}/usr/* ${INSTALL}/usr/
    fi

    # 2. 🔥 O PULO DO GATO: Sobrescrevemos com o binário AARCH64 que acabamos de compilar!
    # Assim garantimos que o emulador é 64-bit real.
    mkdir -p ${INSTALL}/usr/bin
    BIN=$(find ${PKG_BUILD}/build -type f -name "daedalus" | head -n 1)
    if [ -n "$BIN" ]; then
      cp ${BIN} ${INSTALL}/usr/bin/daedalusx64-sa
    fi
    
    chmod +x ${INSTALL}/usr/bin/*

  else
    # Lógica para outras arquiteturas (PC/Generic)
    mkdir -p ${INSTALL}/usr/bin
    mkdir -p ${INSTALL}/usr/config/DaedalusX64
    
    # Pega o binário do caminho do CMake
    BIN=$(find ${PKG_BUILD}/build -type f -name "daedalus" | head -n 1)
    cp ${BIN} ${INSTALL}/usr/bin/daedalusx64-sa
    
    # Copia scripts e configs do diretório do package no EmuELEC
    [ -d "${PKG_DIR}/scripts" ] && cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
    [ -d "${PKG_DIR}/config" ] && cp ${PKG_DIR}/config/* ${INSTALL}/usr/config/DaedalusX64/
    
    # Copia os dados do Source
    cp -r ${PKG_BUILD}/Data/* ${INSTALL}/usr/config/DaedalusX64/
    cp ${PKG_BUILD}/Source/SysGL/HLEGraphics/n64.psh ${INSTALL}/usr/config/DaedalusX64/ 2>/dev/null || true
    
    chmod +x ${INSTALL}/usr/bin/*
  fi
}