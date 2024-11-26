#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

DEST_RESULTS_DIR=/proj/morpheus-PG0/scr-results/maestro/

mkdir -p ${DEST_RESULTS_DIR}
cp ${SCRIPT_DIR}/*.csv ${DEST_RESULTS_DIR}