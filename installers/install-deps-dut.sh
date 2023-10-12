#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

INSTALLERS_SCRIPT="$SCRIPT_DIR/installers.sh"
source $INSTALLERS_SCRIPT

setup
install_maestro
install_dpdk_kmods
install_vpp