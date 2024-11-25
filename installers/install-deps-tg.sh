#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

INSTALLERS_SCRIPT="$SCRIPT_DIR/installers.sh"
source $INSTALLERS_SCRIPT

MLNX=false
# Check if an input parameter is passed and if --mlnx is passed
if [ $# -eq 1 ] && [ "$1" == "--mlnx" ]; then
    MLNX=true
else
    MLNX=false
fi

setup

# If MLNX is true, install doca
if [ "$MLNX" = true ]; then
    install_doca
fi

setup_docker
setup_python_venv
install_dpdk
install_dpdk_kmods
install_pktgen
install_dpdk_burst_replay