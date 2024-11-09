#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

POETRY_CMD="poetry run python"

# Check if poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "Poetry is not installed. Please install it to proceed."
    sudo apt install python3-poetry -y
fi

pushd "${SCRIPT_DIR}"

# Install dependencies with poetry
poetry install > /dev/null 2>&1

$POETRY_CMD plot-data-scr.py

popd