PKG_NAME="matchbox-window-manager"
PKG_VERSION="1.2"
PKG_LICENSE="GPL"
PKG_SITE="https://www.yoctoproject.org/tools-resources/projects/matchbox"
PKG_URL="http://downloads.yoctoproject.org/releases/matchbox/matchbox-window-manager/1.2/matchbox-window-manager-1.2.tar.bz2"
# Dependências básicas do X11 que você já tem compiladas
PKG_DEPENDS_TARGET="toolchain xorgproto libX11 libXext expat xf86-video-armsoc"
PKG_SHORTDESC="Gerenciador de janelas leve para sistemas embarcados"
PKG_LONGDESC="O Matchbox garante que apenas uma janela seja exibida em tela cheia por vez, ideal para consoles."

PKG_IS_ADDON="no"
PKG_AUTORECONF="yes"

pre_configure_target() {
  # Correção de Headers (que fizemos antes)
  sed -i '1i #include <sys/wait.h>' $PKG_BUILD/src/misc.c
  sed -i '1i #include <ctype.h>' $PKG_BUILD/src/keys.c

  # Correção para o GCC Moderno (Erro do MBAtomEnum)
  export CFLAGS="$CFLAGS -fcommon"

  # Otimização Elite
  PKG_CONFIGURE_OPTS_TARGET="$PKG_CONFIGURE_OPTS_TARGET \
                             --disable-composite \
                             --disable-startup-notification \
                             --enable-expat \
                             --enable-standalone"
}
