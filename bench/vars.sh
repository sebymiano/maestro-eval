#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

DATA_DIR="$SCRIPT_DIR/data"
PCAPS_DIR="$SCRIPT_DIR/pcaps"

DUT="" # FIXME: DUT ssh entry
TG=""  # FIXME: TG ssh entry

DUT_EVAL_DIR=~/maestro-eval # Path to this repo on the DUT
TG_EVAL_DIR=~/maestro-eval  # Path to this repo on the TG

DUT_CORES="" # FIXME: comma separated list of cores to be used (e.g. "0,1,2,3")

TG_TX_DEV="" # FIXME: TX PCIe device on the TG
TG_RX_DEV="" # FIXME: RX PCIe device on the TG

TG_TX_CORES=6
TG_RX_CORES=6

ITERATIONS=10
ITERATION_DURATION_SEC=5