#!/bin/sh

# runtime.sh and benchmarks.sh should be sourced before calling any of these functions

# ROOT_DIR: the root directory
# arg1: the index of the first configuration
# arg2: the index of the second configuration
# arg3: the index of the configuration to be used to plot the Dynamic Grift line
function main()
{
    local ROOT_DIR="$1";   shift
    local dyn_config="$1"; shift
    local c1="$1";         shift
    local c2="$1";         shift

    color1="$DGREEN"
    color2="$DPURPLE"
    color3="$SYELLOW"

    local config_str=$(grift-configs -c $c1 $c2)
    local c1t=$(echo $config_str | sed -n 's/\(.*\),.*,.*/\1/p;q')
    local c2t=$(echo $config_str | sed -n 's/.*,\(.*\),.*/\1/p;q')
    local ct=$(echo $config_str | sed -n 's/.*,.*,\(.*\)/\1/p;q')
    
    declare -r COARSE_DIR="${ROOT_DIR}/results/grift/partial/coarse"
    declare -r FINE_DIR="${ROOT_DIR}/results/grift/partial/fine"
    COARSE_BENCHMARK_DIR=$(basename $(ls -td -- "${COARSE_DIR}"/*/ | head -n 1))
    echo "The directory: \"${COARSE_BENCHMARK_DIR}\" is selected for plotting coarse"
    FINE_BENCHMARK_DIR=$(basename $(ls -td -- "${FINE_DIR}"/*/ | head -n 1))
    echo "The directory: \"${FINE_BENCHMARK_DIR}\" is selected for plotting coarse"
    declare -r COARSE_OUT_DIR="${COARSE_DIR}/${COARSE_BENCHMARK_DIR}/output"
    declare -r FINE_OUT_DIR="${FINE_DIR}/${FINE_BENCHMARK_DIR}/output"

    COARSE_PLOT_DIR="${COARSE_OUT_DIR}/${ct}"
    FINE_PLOT_DIR="${FINE_OUT_DIR}/${ct}"
    ALL_DIR="${FINE_PLOT_DIR}/all"
    COARSE_CUMULATIVE_PERFORMANCE_DIR="${COARSE_PLOT_DIR}/cum_perf"
    FINE_CUMULATIVE_PERFORMANCE_DIR="${FINE_PLOT_DIR}/cum_perf"

    if [ ! -d "$COARSE_CUMULATIVE_PERFORMANCE_DIR" ]; then
	echo "ERROR: ${COARSE_CUMULATIVE_PERFORMANCE_DIR} does not exist!"
	exit 1
    fi

    if [ ! -d "$FINE_CUMULATIVE_PERFORMANCE_DIR" ]; then
	echo "ERROR: ${FINE_CUMULATIVE_PERFORMANCE_DIR} does not exist!"
	exit 1
    fi

    local legend_fig="${COARSE_CUMULATIVE_PERFORMANCE_DIR}/legend.png"

    for benchmark in "${BENCHMARKS[@]}"; do
	plot_two_configs_and_racket_coarse_benchmark "$benchmark" $c1 $c2 "$c1t" "$c2t" $dyn_config
    done

    declare -a PAPER_BENCHMARKS=(quicksort sieve ray blackscholes n_body fft matmult)

    for name in "${PAPER_BENCHMARKS[@]}"; do
	convert +append \
	   "${COARSE_CUMULATIVE_PERFORMANCE_DIR}/${name}.png" \
	   "${FINE_CUMULATIVE_PERFORMANCE_DIR}/${name}.png" \
	   "${name}_row.png"
    done

    convert -append \
	    "quicksort_row.png" \
	    "sieve_row.png" \
	    "ray_row.png" \
	    "blackscholes_row.png" \
	    "n_body_row.png" \
	    "fft_row.png" \
	    "matmult_row.png" \
	    "$legend_fig" \
	    "${ROOT_DIR}/Fig8.png"

    rm "quicksort_row.png" \
       "sieve_row.png" \
       "ray_row.png" \
       "blackscholes_row.png" \
       "n_body_row.png" \
       "fft_row.png" \
       "matmult_row.png"

    convert +append \
	    "${ALL_DIR}/sieve.png" \
	    "${ALL_DIR}/n_body.png" \
	    row1.png

    convert +append \
	    "${ALL_DIR}/blackscholes.png" \
	    "${ALL_DIR}/fft.png" \
	    row2.png

    legend_fig="${ALL_DIR}/legend.png"
    
    convert -append row1.png row2.png "$legend_fig" "${ROOT_DIR}/Fig7.png"

    rm row1.png row2.png

    declare -r EXTERNAL_DIR="${ROOT_DIR}/results/grift/external"
    EXTERNAL_BENCHMARK_DIR=$(basename $(ls -td -- "${EXTERNAL_DIR}"/*/ | head -n 1))
    declare -r EXTERNAL_OUT_DIR="${EXTERNAL_DIR}/${EXTERNAL_BENCHMARK_DIR}/output"
    
    local config_str=$(grift-configs -n $dyn_config)
    convert -append \
	    "${EXTERNAL_OUT_DIR}/${config_str}_static.png" \
	    "${EXTERNAL_OUT_DIR}/${config_str}_dynamic.png" \
	    "${ROOT_DIR}/Fig9.png"
}

main "$@"
