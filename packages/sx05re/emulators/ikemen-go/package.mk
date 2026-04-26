# SPDX-License-Identifier: MIT
#
# NextOS Elite Edition — Ikemen GO (M.U.G.E.N engine).
#
# Source: felc18-blip/ikemen-go-nextos branch nextos-gles2 (fork de
# leonkasovan/Ikemen-GO branch SDL2). build/build.sh ja tem target
# 'pi4' que builda com tags=sdl,gles2 — encaixa em Mali-450.

PKG_NAME="ikemen-go"
PKG_VERSION="d5e3ab078576d1ea612bee7150680893dcc2ee81"
PKG_REV="1"
PKG_ARCH="aarch64"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/felc18-blip/ikemen-go-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos-gles2"
PKG_DEPENDS_TARGET="toolchain go:host SDL2 ${OPENGLES} openal-soft sdlgamepadmap"
PKG_TOOLCHAIN="manual"
PKG_SHORTDESC="Open-source M.U.G.E.N fighting engine (SDL2 + GLES2)"
PKG_LONGDESC="Ikemen GO — open-source fighting game engine, MUGEN-compatible."
PKG_IS_TARGET=y
PKG_SECTION="emuelec/emulators"

if [ "${DEVICE}" = "Amlogic-old" ]; then
  TARGET_CFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mtune=cortex-a53 -D__LINUX_ARM_ARCH__=8"
fi

pre_configure_target() {
  export GOOS=linux
  export GOARCH=arm64
  export CGO_ENABLED=1
  # CC/CXX já vêm do LE como cross-compiler quando estamos em make_target;
  # NÃO sobrescrever pra TARGET_CC (não existe nessa toolchain manual).
  # Preservar o que LE setou.

  export CGO_CFLAGS="${CFLAGS} -w -DGL_GLEXT_PROTOTYPES $(pkg-config --cflags sdl2)"
  export CGO_CXXFLAGS="${CXXFLAGS} -w -DGL_GLEXT_PROTOTYPES"
  export CGO_LDFLAGS="${LDFLAGS} -lGLESv2 -lEGL $(pkg-config --libs sdl2)"

  export GOPATH="${PKG_BUILD}/.gopath"
  export GOROOT="$(get_build_dir go)"
  export PATH="${GOROOT}/bin:${PATH}"

  export PKG_CONFIG_PATH="${SYSROOT_PREFIX}/usr/lib/pkgconfig:${SYSROOT_PREFIX}/usr/share/pkgconfig"
}

pre_make_target() {
  cd "${PKG_BUILD}"
  go mod tidy
  chmod -R 775 "${PKG_BUILD}/.gopath" 2>/dev/null || true

  # NextOS: leonkasovan/gl/v3.1/gles2 binding panics on Init when any GLES
  # 3.1 function is missing — Mali-450 is GLES 2.0 only. Replace the
  # 'return errors.New(...)' in InitWithProcAddrFunc with '_ = errors.New(...)'
  # so the loader keeps going. ikemen's gles2 path doesn't actually call
  # the missing functions.
  GL_BINDING="${PKG_BUILD}/.gopath/pkg/mod/github.com/leonkasovan/gl@v0.0.0-20240302015147-1ee9f5b02a16/v3.1/gles2/package.go"
  if [ -f "${GL_BINDING}" ]; then
    chmod +w "${GL_BINDING}"
    sed -i 's|return errors\.New(|_ = errors.New(|g' "${GL_BINDING}"
    # Mali-450 has no core 3.0 VAO functions but does have OES extension.
    # After init, fallback core gpGenVertexArrays/etc to OES variants if
    # core ones returned NULL. Inserts after the OES loads.
    awk '
      /gpGenVertexArraysOES = \(C\.GPGENVERTEXARRAYSOES\)\(getProcAddr/{print; print "\tif gpGenVertexArrays == nil { gpGenVertexArrays = (C.GPGENVERTEXARRAYS)(unsafe.Pointer(gpGenVertexArraysOES)) }"; next}
      /gpBindVertexArrayOES = \(C\.GPBINDVERTEXARRAYOES\)\(getProcAddr/{print; print "\tif gpBindVertexArray == nil { gpBindVertexArray = (C.GPBINDVERTEXARRAY)(unsafe.Pointer(gpBindVertexArrayOES)) }"; next}
      /gpDeleteVertexArraysOES = \(C\.GPDELETEVERTEXARRAYSOES\)\(getProcAddr/{print; print "\tif gpDeleteVertexArrays == nil { gpDeleteVertexArrays = (C.GPDELETEVERTEXARRAYS)(unsafe.Pointer(gpDeleteVertexArraysOES)) }"; next}
      /gpIsVertexArrayOES = \(C\.GPISVERTEXARRAYOES\)\(getProcAddr/{print; print "\tif gpIsVertexArray == nil { gpIsVertexArray = (C.GPISVERTEXARRAY)(unsafe.Pointer(gpIsVertexArrayOES)) }"; next}
      {print}
    ' "${GL_BINDING}" > "${GL_BINDING}.new" && mv "${GL_BINDING}.new" "${GL_BINDING}"
  fi

  # NextOS: glfont's shader_gles.go prepends "#version %d es\n" to ALL
  # shaders, but GLSL ES 1.00 (Mali-450's max) requires plain "#version 100"
  # WITHOUT the "es" suffix. Compile fails with cryptic panic. Patch the
  # version 100 case to omit "es".
  GLFONT_SHADER="${PKG_BUILD}/.gopath/pkg/mod/github.com/leonkasovan/glfont@v0.0.0-20240116222114-fd1d8a52b71d/shader_gles.go"
  if [ -f "${GLFONT_SHADER}" ]; then
    chmod +w "${GLFONT_SHADER}"
    # 1) #version 100 (sem 'es' suffix) — Mali-450 nao aceita 100 es
    sed -i 's|fmt\.Sprintf("#version %d es\\n", GLSLVersion)|fmt.Sprintf("#version %d\\n", GLSLVersion)|g' "${GLFONT_SHADER}"
    # 2) GLSL ES 1.00 fragment shader requer precision specifier. O else
    # branch (legacy path) nao tem. Insere apos o '#define COMPAT_FRAGCOLOR
    # gl_FragColor'. Awk evita escapes problematicos do sed.
    awk 'BEGIN{ins=0} /#define COMPAT_FRAGCOLOR gl_FragColor/ && !ins {print; print "precision mediump float;"; ins=1; next} {print}' "${GLFONT_SHADER}" > "${GLFONT_SHADER}.new" && mv "${GLFONT_SHADER}.new" "${GLFONT_SHADER}"
  fi
}

make_target() {
  cd "${PKG_BUILD}"
  chmod a+x build/build.sh
  cd ./build && ./build.sh pi4
  chmod -R 775 "${PKG_BUILD}/.gopath" 2>/dev/null || true
}

makeinstall_target() {
  mkdir -p "${INSTALL}/usr/bin"
  mkdir -p "${INSTALL}/usr/share/ikemen_go"

  mkdir -p ${INSTALL}/usr/config
  cp -rf ${PKG_DIR}/src/asound-ikemen.conf ${INSTALL}/usr/config/

  cp -f "${PKG_DIR}/src/Ikemen_Go.sh" "${INSTALL}/usr/bin/Ikemen_Go.sh"
  cp "${PKG_BUILD}/bin/Ikemen_Go_"* "${INSTALL}/usr/bin/Ikemen_Go"

  cp -rf "${PKG_BUILD}/data" "${INSTALL}/usr/share/ikemen_go"
  cp -rf "${PKG_BUILD}/external" "${INSTALL}/usr/share/ikemen_go"
  cp -rf "${PKG_BUILD}/font" "${INSTALL}/usr/share/ikemen_go"

  chmod +x "${INSTALL}/usr/bin/Ikemen_Go.sh"
  chmod +x "${INSTALL}/usr/bin/Ikemen_Go"
}
