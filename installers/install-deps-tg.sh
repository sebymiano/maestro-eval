#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

INSTALLERS_SCRIPT="$SCRIPT_DIR/installers.sh"
source $INSTALLERS_SCRIPT

setup
setup_python_venv
install_dpdk
install_dpdk_kmods
install_pktgen