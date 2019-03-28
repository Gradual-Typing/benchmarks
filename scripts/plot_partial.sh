#!/bin/sh

# needed so that anyone can access the files
umask 000

function main()
{
    ROOT_DIR="$1";   shift
    mode="$1";       shift
    dyn_config="$1"; shift

    declare -r LIB_DIR="${ROOT_DIR}/scripts/lib"
    declare -r LB_DIR="${ROOT_DIR}/results/grift/partial/${mode}"
    declare -r RKT_DIR="${ROOT_DIR}/results/typed_racket/partial/coarse"
    echo "${LB_DIR}"
    if [ -z ${BENCHMARK_DIR+x} ]; then
	# if the variable is not set, pick the most recent experiment directory
	BENCHMARK_DIR=$(basename $(ls -td -- "${LB_DIR}"/*/ | head -n 1))
	echo "The directory: \"${BENCHMARK_DIR}\" is selected for plotting"
    fi
    if [ -z ${RKT_BENCHMARK_DIR+x} ]; then
	# if the variable is not set, pick the most recent experiment directory
	RKT_BENCHMARK_DIR=$(basename $(ls -td -- "${RKT_DIR}"/*/ | head -n 1))
	echo "The directory: \"${RKT_BENCHMARK_DIR}\" is selected for plotting"
    fi
    declare -r EXP_DIR="${LB_DIR}/${BENCHMARK_DIR}"
    declare -r DATA_DIR="${EXP_DIR}/data"
    declare -r OUT_DIR="${EXP_DIR}/output"
    declare -r TMP_DIR="${EXP_DIR}/tmp"

    declare -r RKT_EXP_DIR="${RKT_DIR}/${RKT_BENCHMARK_DIR}"
    declare -r RKT_DATA_DIR="${RKT_EXP_DIR}/data"
    declare -r RKT_OUT_DIR="${RKT_EXP_DIR}/output"
    declare -r RKT_TMP_DIR="${RKT_EXP_DIR}/tmp"

    DPURPLE='#7b3294'
    DGREEN='#008837'
    SYELLOW='#fdb863'
    SPURPLE='#5e3c99'

    . ${LIB_DIR}/runtime.sh
    . ${LIB_DIR}/benchmarks.sh
    . ${LIB_DIR}/plotting_one_config_fine.sh
    . ${LIB_DIR}/plotting_two_configs_fine.sh
    . ${LIB_DIR}/plotting_one_config_coarse.sh
    # . ${LIB_DIR}/plotting_two_configs_coarse.sh
    . ${LIB_DIR}/plotting_two_configs_and_racket_coarse.sh

    local i j
    if [ "$mode" = "fine" ]; then
	while (( "$#" )); do
            i=$1; shift
            j=$1; shift
            plot_two_configs_fine $i $j $dyn_config
	    plot_one_config_fine $i $dyn_config
	    plot_one_config_fine $j $dyn_config
	done
    elif [ "$mode" = "coarse" ]; then
	while (( "$#" )); do
            i=$1; shift
            j=$1; shift
            plot_two_configs_and_racket_coarse $i $j $dyn_config
	    plot_one_config_coarse $i $dyn_config
	    plot_one_config_coarse $j $dyn_config
	done
    else
	echo "${mode} is invalid mode, fine or coarse are expected"
	exit -1
    fi
}

main "$@"
