#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

DATA_DIR="$SCRIPT_DIR/data"
PCAPS_DIR="$SCRIPT_DIR/pcaps"

DUT=geodude
TG=graveler

DUT_EVAL_DIR=~/maestro-eval
TG_EVAL_DIR=~/maestro-eval

DUT_CORES="16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31"

TG_TX_DEV="0000:af:00.1"
TG_RX_DEV="0000:af:00.0"

TG_TX_CORES=6
TG_RX_CORES=6

ITERATIONS=10
ITERATION_DURATION_SEC=5