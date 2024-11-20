#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

pushd "${SCRIPT_DIR}/out/"

for file in *.pdf; do     
    pdftoppm -png -f 1 -singlefile "$file" "${file%.pdf}"; 
done

popd