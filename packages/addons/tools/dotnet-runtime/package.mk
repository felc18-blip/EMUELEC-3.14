# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="dotnet-runtime"
PKG_REV="3"
PKG_ARCH="any"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.microsoft.com/"
PKG_DEPENDS_TARGET="toolchain icu aspnet6-runtime aspnet8-runtime aspnet9-runtime"
PKG_SECTION="tools"
PKG_SHORTDESC="ASP.NET Core Runtime"
PKG_LONGDESC="ASP.NET Core Runtime ($(get_pkg_version aspnet8-runtime)) and ($(get_pkg_version aspnet9-runtime)) enables you to run existing console/web/server applications."
PKG_TOOLCHAIN="manual"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="ASP.Net Core Runtimes"
PKG_ADDON_PROJECTS="any !RPi1"
PKG_ADDON_TYPE="xbmc.python.script"
PKG_MAINTAINER="Anton Voyl (awiouy)"

addon() {
  local BIN_DIR="${ADDON_BUILD}/${PKG_ADDON_ID}/bin"
  local ICU_VER=$(get_pkg_version icu | cut -f 1 -d .)

  mkdir -p "${BIN_DIR}"

  # 1. COPIAR AMBIENTES (Ordem importa: o mais novo por último para garantir o binário 'dotnet' v9)
  cp -r $(get_build_dir aspnet6-runtime)/* "${BIN_DIR}/"
  cp -r $(get_build_dir aspnet8-runtime)/* "${BIN_DIR}/"
  cp -r $(get_build_dir aspnet9-runtime)/* "${BIN_DIR}/"

  # 2. LOOP DE BLINDAGEM DE GLOBALIZAÇÃO (AppLocal ICU)
  # Aplicamos a correção nas três versões para garantir que o Kernel 3.14 não dê erro.

  for VER in "6.0" "8.0" "9.0"; do
    # Ajuste para pegar o nome correto do pacote (aspnet6, aspnet8, aspnet9)
    local PKG_PREFIX="aspnet${VER:0:1}"
    local PKG_VER=$(get_pkg_version ${PKG_PREFIX}-runtime)
    local FRAMEWORK_DIR="${BIN_DIR}/shared/Microsoft.NETCore.App/${PKG_VER}"
    local CONFIG_FILE="${FRAMEWORK_DIR}/Microsoft.NETCore.App.runtimeconfig.json"

    if [ -d "${FRAMEWORK_DIR}" ]; then
      # Copia as libs de tradução/data do sistema para dentro do framework .NET
      cp -L $(get_install_dir icu)/usr/lib/libicu*.so.?? "${FRAMEWORK_DIR}/"

      # Patch no JSON para forçar o .NET a ler as libs locais no Kernel 3.14
      if [ -f "${CONFIG_FILE}" ]; then
        sed -e "s/\"tfm\": \"net${VER}\"/&,\n      \"configProperties\": {\n        \"System.Globalization.AppLocalIcu\": \"${ICU_VER}\"\n      }/" \
            -i "${CONFIG_FILE}"
      fi
    fi
  done
}
