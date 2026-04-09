#!/bin/sh

# 1. Carrega as variáveis de ambiente do sistema
. /etc/profile

# 2. Define onde o emulador e as libs estão
CONFIG_DIR="/storage/.config/drastic-advanced"

# 3. Prioriza as suas libs customizadas sobre as do sistema
export LD_LIBRARY_PATH="${CONFIG_DIR}/libs:$LD_LIBRARY_PATH"

# 4. Entra na pasta para garantir que os arquivos de configuração sejam lidos
cd "${CONFIG_DIR}"

# 5. Lança o emulador passando o jogo e substitui o processo do shell
exec ./drastic "$@"
