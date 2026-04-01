PKG_NAME="ca-certificates"
PKG_VERSION="1.0"
PKG_LICENSE="MPL"
PKG_SITE="https://curl.se/docs/caextract.html"
PKG_URL="https://curl.se/ca/cacert.pem"
PKG_SOURCE_NAME="cacert.pem"
PKG_SHA256="b6e66569cc3d438dd5abe514d0df50005d570bfc96c14dca8f768d020cb96171"
PKG_ARCH="any"
PKG_TOOLCHAIN="manual"

unpack() {
  mkdir -p ${PKG_BUILD}

  # encontra o cacert.pem onde quer que o build tenha colocado
  CERT_FILE=$(find ${ROOT}/sources -name "cacert.pem" | head -n1)

  if [ -z "$CERT_FILE" ]; then
    echo "ERRO: cacert.pem não encontrado"
    exit 1
  fi

  cp "$CERT_FILE" ${PKG_BUILD}/cacert.pem
}

makeinstall_target() {
  mkdir -p ${INSTALL}/etc/ssl/certs

  install -m 0644 ${PKG_BUILD}/cacert.pem \
    ${INSTALL}/etc/ssl/certs/ca-certificates.crt

  ln -sf ca-certificates.crt ${INSTALL}/etc/ssl/certs/ca-bundle.crt
  ln -sf ca-certificates.crt ${INSTALL}/etc/ssl/certs/ca-certificates.pem
}
