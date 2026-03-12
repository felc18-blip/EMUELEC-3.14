#!/bin/bash
# Script para criar o acesso ao PortMaster nas ROMs
mkdir -p /storage/roms/ports_scripts

if [ ! -f "/storage/roms/ports_scripts/PortMaster.sh" ]; then
    echo "#!/bin/bash" > "/storage/roms/ports_scripts/PortMaster.sh"
    echo "/usr/bin/start_portmaster.sh" >> "/storage/roms/ports_scripts/PortMaster.sh"
    chmod +x "/storage/roms/ports_scripts/PortMaster.sh"
fi