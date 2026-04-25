# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="fbneoSA"
PKG_VERSION="47f12dd9296d4297b1d3daec3e91c4d3d2c0f80a"
PKG_ARCH="aarch64"
PKG_LICENSE="Custom"
PKG_SITE="https://github.com/finalburnneo/FBNeo"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain SDL2 gl4es"
PKG_LONGDESC="https://github.com/finalburnneo/FBNeo/blob/master/src/license.txt"
GET_HANDLER_SUPPORT="git"
PKG_TOOLCHAIN="make"

PKG_MAKE_OPTS_TARGET=" sdl2 RELEASEBUILD=1"

# Forçamos as flags de linkagem a incluírem o pthread explicitamente no final
export LDFLAGS="-L${SYSROOT_PREFIX}/usr/lib -L$(get_install_dir gl4es)/usr/lib -Wl,-rpath-link,$(get_install_dir gl4es)/usr/lib -lpthread -ldl"

pre_configure_target() {
    # 1. Seus SEDs de diretórios que funcionam
    sed -i "s|\`sdl2-config|\`${SYSROOT_PREFIX}/usr/bin/sdl2-config|g" makefile.sdl2
    sed -i "s|objdir	= obj/|objdir	= ${PKG_BUILD}/obj/|" makefile.sdl2
    sed -i "s|srcdir	= src/|srcdir	= ${PKG_BUILD}/src/|" makefile.sdl2

    # 2. Criar os diretórios de objetos (essencial para evitar o Error 2)
    mkdir -p ${PKG_BUILD}/obj
    cd ${PKG_BUILD}
    find src -type d -exec mkdir -p ${PKG_BUILD}/obj/{} \;
    cd -

    # 2b. NextOS: gl4es nao copia libGL.so pro sysroot — fbneoSA precisa
    # encontrar -lGL. Symlink temporario.
    GL4ES_LIB="$(get_install_dir gl4es)/usr/lib/libGL.so"
    if [ -f "$GL4ES_LIB" ] && [ ! -e "${SYSROOT_PREFIX}/usr/lib/libGL.so" ]; then
      ln -sf "$GL4ES_LIB" "${SYSROOT_PREFIX}/usr/lib/libGL.so"
    fi

    # 3. TRAVA TOTAL NO LINKER (Resolve o erro "unsupported ELF machine")
    # NextOS: em vez de tentar substituir CC/CXX/LD inline (regex broke makefile
    # com if/else/endif blocks e linhas de continuacao com `\`), simplesmente
    # apenda overrides no final — Make usa a ULTIMA definicao de cada variavel.
    # Localiza native gcc/g++ p/ HOST_CC/HOST_CXX (build de tools rodam no x86_64)
    NATIVE_CC=$(command -v gcc)
    NATIVE_CXX=$(command -v g++)

    cat >> makefile.sdl2 <<EOF

# === NextOS: cross-compile overrides (last-write-wins) ===
CC := ${CC}
CXX := ${CXX}
LD := ${CXX}
ld := ${CXX}
# HOST_* tem que ser native — ctv_make.exe e similares rodam no host x86_64
HOST_CC := ${NATIVE_CC}
HOST_CXX := ${NATIVE_CXX}
HOST_CFLAGS :=
HOST_CXXFLAGS :=
HOST_LDFLAGS :=
EOF

    # 4. Flags para o S905L (64-bit)
    echo "PTR64 = 1" >> makefile.sdl2
    echo "LSB_FIRST = 1" >> makefile.sdl2
    
    unset MAKELEVEL
}

makeinstall_target() {
    mkdir -p ${INSTALL}/usr/bin
    [ -f "${PKG_BUILD}/fbneo" ] && cp -rf ${PKG_BUILD}/fbneo ${INSTALL}/usr/bin/
    [ -f "${PKG_BUILD}/fbneo.sdl" ] && cp -rf ${PKG_BUILD}/fbneo.sdl ${INSTALL}/usr/bin/fbneo

    cp -rf ${PKG_BUILD}/src/license.txt ${INSTALL}/usr/bin/fbneo_license.txt

    if [ -d "${PKG_DIR}/scripts" ]; then
        cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
    fi

    # NextOS: gptokeyb config p/ Select+Start = kill fbneo
    mkdir -p ${INSTALL}/usr/config/emuelec/configs/gptokeyb
    [ -f "${PKG_DIR}/config/gptokeyb/fbneo.gptk" ] && \
      cp -f ${PKG_DIR}/config/gptokeyb/fbneo.gptk \
            ${INSTALL}/usr/config/emuelec/configs/gptokeyb/fbneo.gptk
}