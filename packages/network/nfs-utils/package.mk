# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org) / Adapted for EmuELEC

PKG_NAME="nfs-utils"
PKG_VERSION="2.9.1"
PKG_SHA256="302846343bf509f8f884c23bdbd0fe853b7f7cbb6572060a9082279d13b21a2c"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="http://www.linux-nfs.org/"
PKG_URL="https://www.kernel.org/pub/linux/utils/nfs-utils/${PKG_VERSION}/nfs-utils-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain systemd sqlite libtirpc libevent keyutils libnl libxml2 readline rpcbind util-linux"
PKG_LONGDESC="Linux NFS userland utility package"

post_unpack() {
  # Mantido: copia o arquivo de mount customizado do diretório do pacote (se existir)
  if [ -d "$PKG_DIR/system.d" ]; then
    cp $PKG_DIR/system.d/* $PKG_BUILD/systemd/ 2>/dev/null || true
  fi

  # Mantido: Move caminhos do /var/lib/nfs (que é read-only no EmuELEC) para /run/nfs (tmpfs)
  find $PKG_BUILD -type f -exec sed -i \
    -e 's|/var/lib/nfs|/run/nfs|g' \
    -e 's|var-lib-nfs|run-nfs|g' {} \;

  if [ -f "$PKG_BUILD/systemd/var-lib-nfs-rpc_pipefs.mount" ]; then
    mv $PKG_BUILD/systemd/var-lib-nfs-rpc_pipefs.mount \
       $PKG_BUILD/systemd/run-nfs-rpc_pipefs.mount
  fi
  if [ -f "$PKG_BUILD/systemd/var-lib-nfs-rpc_pipefs.mount.in" ]; then
    mv $PKG_BUILD/systemd/var-lib-nfs-rpc_pipefs.mount.in \
       $PKG_BUILD/systemd/run-nfs-rpc_pipefs.mount.in
  fi
}

pre_configure_target() {
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}
CFLAGS+=" -Wno-error"
CFLAGS+=" -DNETLINK_EXT_ACK=0"
PKG_CONFIGURE_OPTS_TARGET=" \
    --with-systemd=/usr/lib/systemd/system \
    --with-nfsconfig=/storage/.config/nfs.conf \
    --with-statduser=$(whoami) \
    --with-statedir=/run/nfs \
    --enable-nfsv4 \
    --disable-nfsv41 \
    --enable-tirpc \
    --enable-uuid \
    --disable-gss \
    --disable-ipv6 \
    --disable-nfsdcld \
    --disable-nfsdcltrack \
    --disable-nfsrahead \
    --disable-ldap \
    --without-netlink \
    --without-tcp-wrappers \
    --disable-nfsdctl"

  # Mantido: Força os caminhos de configuração para a partição mutável do EmuELEC (/storage/.config)
  # /etc/exports
  CFLAGS+=" -D_PATH_EXPORTS=\\\"/storage/.config/exports\\\""
  # /etc/exports.d
  CFLAGS+=" -D_PATH_EXPORTS_D=\\\"/storage/.config/exports.d\\\""
  # /etc/idmapd.conf
  CFLAGS+=" -D_PATH_IDMAPDCONF=\\\"/storage/.config/idmapd.conf\\\""
  # EmuELEC não possui usuário/grupo nobody
  CFLAGS+=" -DNFS4NOBODY_USER=\\\"root\\\""
  CFLAGS+=" -DNFS4NOBODY_GROUP=\\\"root\\\""
}

post_makeinstall_target() {
  mkdir -p $INSTALL/usr/config

  [ -f "nfs.conf" ] && cp nfs.conf $INSTALL/usr/config/
  [ -f "support/nfsidmap/idmapd.conf" ] && cp support/nfsidmap/idmapd.conf $INSTALL/usr/config/

  if [ -d "$PKG_DIR/config" ]; then
    cp $PKG_DIR/config/* $INSTALL/usr/config/ 2>/dev/null || true
  fi

  # Remove diretório run da instalação (EmuELEC usa tmpfs na ram)
  rm -fr "$INSTALL/run"

  # Consolida executáveis no /usr/sbin (Padrão do EmuELEC)
  if [ -d "$INSTALL/sbin" ]; then
    mkdir -p $INSTALL/usr/sbin
    chmod 755 $INSTALL/sbin/*
    mv $INSTALL/sbin/* $INSTALL/usr/sbin/
    rmdir $INSTALL/sbin
  fi
}

post_install() {
  # Mantido: Habilita o serviço do systemd na imagem final
  enable_service nfs-server.service
}
