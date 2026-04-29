PKG_NAME="openvpn"
PKG_VERSION="2.7.3"
PKG_SHA256="24f54cb0759330762f1140b874c07c8542c6a08b13457d8570dafd387d49397a"
PKG_LICENSE="GPL"
PKG_SITE="https://openvpn.net"
PKG_URL="https://swupdate.openvpn.org/community/releases/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain lzo openssl libcap-ng"
PKG_LONGDESC="A full featured SSL VPN software solution that integrates OpenVPN server capabilities."

PKG_TOOLCHAIN="autotools"
PKG_AUTORECONF="yes"

PKG_CONFIGURE_OPTS_TARGET="
  ac_cv_have_decl_TUNSETPERSIST=no \
  --disable-server \
  --disable-plugins \
  --enable-iproute2 IPROUTE=/sbin/ip \
  --enable-management \
  --enable-fragment \
  --disable-lz4 \
  --disable-multihome \
  --disable-port-share \
  --disable-debug
"

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  ln -sf ../sbin/openvpn ${INSTALL}/usr/bin/openvpn
}
