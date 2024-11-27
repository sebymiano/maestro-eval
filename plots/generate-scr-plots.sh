#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

POETRY_CMD="poetry run python"

# Check if poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "Poetry is not installed. Please install it to proceed."
    sudo apt install python3-poetry -y
fi

# Initialize variables
DATA_DIR_ARG=""
OUT_DIR_ARG=""

# Check for parameters
for arg in "$@"; do
    if [[ "$arg" == --data-dir=* ]]; then
        DATA_DIR_ARG="$arg"
    elif [[ "$arg" == --out-dir=* ]]; then
        OUT_DIR_ARG="$arg"
    fi
done

pushd "${SCRIPT_DIR}"

# Install dependencies with poetry
poetry install > /dev/null 2>&1

# Construct the command with the provided arguments
CMD="$POETRY_CMD plot-data-scr.py"
if [[ -n "$DATA_DIR_ARG" || -n "$OUT_DIR_ARG" ]]; then
    CMD+=" $DATA_DIR_ARG $OUT_DIR_ARG"
fi

# Run the script
eval "$CMD"

popd