#!/bin/bash

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

${CURRENT_EXPERIMENT_DIR}/scr-nfs/run_tests_caida.sh --no-scr
${CURRENT_EXPERIMENT_DIR}/bench/technologies/technologies-caida.sh

${CURRENT_EXPERIMENT_DIR}/scr-nfs/run_tests_imc_scr.sh --no-scr
${CURRENT_EXPERIMENT_DIR}/bench/technologies/technologies-imc-scr.sh

${CURRENT_EXPERIMENT_DIR}/scr-nfs/run_tests_uniform.sh --no-scr
${CURRENT_EXPERIMENT_DIR}/bench/technologies/technologies-uniform.sh

${CURRENT_EXPERIMENT_DIR}/scr-nfs/run_tests_zipf.sh --no-scr
${CURRENT_EXPERIMENT_DIR}/bench/technologies/technologies-zipf.sh

${CURRENT_EXPERIMENT_DIR}/scr-nfs/run_tests_single.sh --no-scr
${CURRENT_EXPERIMENT_DIR}/bench/technologies/technologies-single.sh