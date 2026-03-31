# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="kmod"
PKG_VERSION="34.2"
PKG_SHA256="5a5d5073070cc7e0c7a7a3c6ec2a0e1780850c8b47b3e3892226b93ffcb9cb54"
PKG_LICENSE="GPL"
PKG_SITE="https://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git"
PKG_URL="https://www.kernel.org/pub/linux/utils/kernel/kmod/${PKG_NAME}-${PKG_VERSION}.tar.xz"

# ✔️ Mudança para o sistema Meson/Ninja (necessário na 34.2)
PKG_DEPENDS_HOST="meson:host ninja:host"
PKG_DEPENDS_TARGET="toolchain openssl"

PKG_LONGDESC="kmod offers the needed flexibility and fine grained control over insertion, removal, configuration and listing of kernel modules."
PKG_BUILD_FLAGS="-gold -mold"

# ✔️ Flags de configuração (Mantendo sua escolha de sem compressão XZ/ZLIB/ZSTD)
PKG_MESON_OPTS_COMMON="-Dbashcompletiondir=no \
                       -Dfishcompletiondir=no \
                       -Dzshcompletiondir=no \
                       -Dzstd=disabled \
                       -Dxz=disabled \
                       -Dzlib=disabled \
                       -Dopenssl=enabled \
                       -Dtools=true \
                       -Ddebug-messages=false \
                       -Dbuild-tests=false \
                       -Dmanpages=false \
                       -Ddocs=false"

PKG_MESON_OPTS_HOST="${PKG_MESON_OPTS_COMMON} -Dlogging=false"
PKG_MESON_OPTS_TARGET="${PKG_MESON_OPTS_COMMON} -Dlogging=true"

# 🛡️ MANTENDO A LÓGICA DE POST-INSTALL ORIGINAL 🛡️

post_makeinstall_host() {
  # Lógica Original: Mantém o depmod do host vinculado ao kmod novo
  ln -sf kmod ${TOOLCHAIN}/bin/depmod
}

post_makeinstall_target() {
  # 1. Links de compatibilidade (Igual ao seu script da v30)
  mkdir -p ${INSTALL}/usr/sbin
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/lsmod
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/insmod
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/rmmod
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/modinfo
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/modprobe
    ln -sf /usr/bin/kmod ${INSTALL}/usr/sbin/depmod

  # 2. Configuração do modprobe.d no /storage (Lógica Original)
  mkdir -p ${INSTALL}/etc
    # Removemos o diretório físico se o Meson criou um, para forçar o link simbólico
    rm -rf ${INSTALL}/etc/modprobe.d
    ln -sf /storage/.config/modprobe.d ${INSTALL}/etc/modprobe.d

  # 3. Diretório de config do usuário (Lógica Original)
  mkdir -p ${INSTALL}/usr/config/modprobe.d
}