#!/bin/sh

function main()
{
    TEST_DIR="."
    DATE="temp"
    declare -r LIB_DIR="${TEST_DIR}/lib"
    declare -r LB_DIR="${TEST_DIR}/lattice_bins"
    declare -r EXP_DIR="${LB_DIR}/${DATE}"
    declare -r DATA_DIR="${EXP_DIR}/data"
    declare -r OUT_DIR="${EXP_DIR}/output"
    declare -r TMP_DIR="${EXP_DIR}/tmp"

    . ${LIB_DIR}/runtime.sh
    . ${LIB_DIR}/plotting.sh

    dyn_config=17

    plot 19 17 $dyn_config
    plot 17 7 $dyn_config
    plot 17 13 $dyn_config
    plot 17 8 $dyn_config
}

main "$@"
