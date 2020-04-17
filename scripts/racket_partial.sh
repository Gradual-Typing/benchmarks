#!/bin/sh

set -euo pipefail
declare -r PRECISION=5
TIMEFORMAT=%R

# needed so that anyone can access the files
umask 000

# $1 - baseline system
# $3 - directory path of the samples, it should have the binaries. Also, the
#      directory name is the same as the benchmark name
# $4 - space-separated benchmark arguments
# $5 - disk aux name
# $RETURN - number of configurations
run_config()
{
    local baseline_system="$1";        shift
    local samples_directory_path="$1"; shift
    local input_filename="$1";         shift
    local disk_aux_name="$1";          shift

    local name=$(basename "$samples_directory_path")
    local logfile="${DATA_DIR}/${name}${disk_aux_name}.log"
    local cache_file="${TMP_DIR}/typed_racket/${name}${disk_aux_name}.cache"

    if [ -f $cache_file ]; then
        RETURN=$(cat "$cache_file")
    else
        local n=0 b
        $baseline_system "$name" "$input_filename" "$disk_aux_name"
        local baseline="$RETURN"
        echo "name,time,slowdown,speedup" > "$logfile"
        for sample_path in "$samples_directory_path/"*/; do
            let n=n+1
            local sample_number="$(basename $sample_path)"

	    get_typed_racket_config_runtime "$name" "$sample_path" "${input_filename}" "$disk_aux_name"
            local t="$RETURN"
            local speedup=$(echo "${baseline}/${t}" | \
                                bc -l | \
                                awk -v p="$PRECISION" '{printf "%.*f\n", p,$0}')
            local slowdown=$(echo "${t}/${baseline}" | \
                                 bc -l | \
                                 awk -v p="$PRECISION" '{printf "%.*f\n", p,$0}')
            echo $n $sample_path $speedup
            printf "%s,%.2f,%.${PRECISION}f,%.${PRECISION}f,%.${PRECISION}f" \
                   $sample_number $t $slowdown $speedup >> "$logfile"

            printf "\n" >> "$logfile"
        done
        RETURN="$n"
        echo "$RETURN" > "$cache_file"
    fi
}

# $1  - baseline system
# $2  - statically typed system
# $3  - dynamically typed system
# $6  - $samples_directory_path
# $7  - space-separated benchmark arguments
# $10 - disk aux name
gen_output()
{
    local baseline_system="$1";        shift
    local static_system="$1";          shift
    local dynamic_system="$1";         shift
    local samples_directory_path="$1"; shift
    local input_filename="$1";         shift
    local disk_aux_name="$1";          shift

    local name=$(basename "$samples_directory_path")

    run_config $baseline_system "$samples_directory_path" "$input_filename" "$disk_aux_name"

    $static_system "$name" "$input_filename" "$disk_aux_name"
    $dynamic_system "$name" "$input_filename" "$disk_aux_name"
}

# $1  - baseline system
# $2  - statically typed system
# $3  - dynamically typed system
# $6  - benchmark filename without extension
# $7  - space-separated benchmark arguments
# $10 - aux name
run_benchmark()
{
    local baseline_system="$1"; shift
    local static_system="$1";   shift
    local dynamic_system="$1";  shift
    local benchmark_name="$1";  shift
    local input_filename="$1";  shift
    local aux_name="$1";        shift

    local samples_directory_path="${TMP_DIR}/partial/${benchmark_name}"
    local static_source_path="${TMP_DIR}/typed_racket/${benchmark_name}/modules"
    local dyn_source_path="${TMP_DIR}/racket/${benchmark_name}/modules"

    local disk_aux_name="" print_aux_name=""
    if [[ ! -z "${aux_name}" ]]; then
        disk_aux_name="_${aux_name}"
        print_aux_name=" (${aux_name})"
    fi

    local benchmark_args_file="${TMP_DIR}/${benchmark_name}${disk_aux_name}.args"
    local input="$(cat ${INPUT_DIR}/${benchmark_name}/${input_filename})"
    if [ -f benchmark_args_file ]; then
        local old_input=$(cat "$benchmark_args_file")
        if [ ! $old_input == $input ]; then
            echo "input changed mid test" 1>&2
            exit 1
        fi
    else
        printf "Benchmark\t:%s\n" "$benchmark_name" >> "$PARAMS_LOG"
        printf "Args\t\t:%s\n" "$input" >> "$PARAMS_LOG"
        echo "$input" > "$benchmark_args_file"
    fi

    if [ ! -d "$samples_directory_path" ]; then
	# rm -rf "$samples_directory_path"
	cp -a "$static_source_path/" "${TMP_DIR}/partial/typed"
	cp -a "$dyn_source_path/" "${TMP_DIR}/partial/untyped"
	
	racket ../typed_racket_benchmarks/utilities/make-configurations.rkt "${TMP_DIR}/partial"
    
	# the source is created by the typed racket dynamizer
	mv "partial-configurations" "${samples_directory_path}"
	# deleting the source files so it does not mingle with sources of
	# other benchmarks where modules might happen to share the same name
	rm -rf "${TMP_DIR}/partial/typed" "${TMP_DIR}/partial/untyped"
	
	gen_output $baseline_system $static_system $dynamic_system "$samples_directory_path" "$input_filename" "$disk_aux_name"
    fi
}

# $1 - baseline system
# $2 - statically typed system
# $3 - dynamically typed system
run_experiment()
{
    local baseline_system="$1"; shift
    local static_system="$1";   shift
    local dynamic_system="$1";  shift

    if [ "$INPUT_TYPE" == "test" ]; then
	for ((i=0;i<${#BENCHMARKS[@]};++i)); do
            run_benchmark $baseline_system $static_system $dynamic_system "${BENCHMARKS[i]}" "${BENCHMARKS_ARGS_TRIVIAL[i]}"  ""
	done
    elif [ "$INPUT_TYPE" == "release" ]; then
	for ((i=0;i<${#BENCHMARKS[@]};++i)); do
            run_benchmark $baseline_system $static_system $dynamic_system "${BENCHMARKS[i]}" "${BENCHMARKS_ARGS_PARTIAL_COARSE[i]}"  ""
	done
    else
	echo "ERROR: INPUT_TYPE: expected test or release but got ${INPUT_TYPE}"
	exit 1
    fi
}

main()
{
    USAGE="Usage: $0 root loops [fresh|date] INPUT_TYPE"
    if [ "$#" == "0" ]; then
        echo "$USAGE"
        exit 1
    fi
    ROOT_DIR="$1";   shift
    LOOPS="$1";      shift
    local date="$1"; shift
    INPUT_TYPE="$1"; shift
    OVERWRITE="$1";  shift

    declare -r RESULTS_DIR="${ROOT_DIR}/results/typed_racket/partial/coarse"
    if [ "$date" == "fresh" ]; then
        declare -r DATE=`date +%Y_%m_%d_%H_%M_%S`
    elif [ "$date" == "test" ]; then
        declare -r DATE="test"
    else
        declare -r DATE="$date"
        if [ ! -d "$RESULTS_DIR/$DATE" ]; then
            echo "$RESULTS_DIR/$DATE" "Directory not found"
            exit 1
        fi
    fi

    declare -r EXP_DIR="$RESULTS_DIR/$DATE"
    declare -r DATA_DIR="$EXP_DIR/data"
    declare -r OUT_DIR="$EXP_DIR/output"
    declare -r GMEANS="${OUT_DIR}/geometric-means.csv"
    declare -r TMP_DIR="$EXP_DIR/tmp"
    declare -r SRC_DIR="${ROOT_DIR}/src"
    declare -r INPUT_DIR="${ROOT_DIR}/inputs"
    declare -r OUTPUT_DIR="${ROOT_DIR}/outputs"
    declare -r LIB_DIR="${ROOT_DIR}/scripts/lib"
    declare -r PARAMS_LOG="$EXP_DIR/params.txt"

    if [ "$OVERWRITE" = true ]; then
	rm -rf "$EXP_DIR"
	echo "$EXP_DIR has been deleted."
    fi

    # Check to see if all is right in the world
    if [ ! -d $ROOT_DIR ]; then
        echo "directory not found: ${ROOT_DIR}" 1>&2
        exit 1
    elif [ ! -d $SRC_DIR ]; then
        echo "directory not found: ${SRC_DIR}" 1>&2
        exit 1
    elif [ ! -d $INPUT_DIR ]; then
        echo "directory not found: ${INPUT_DIR}" 1>&2
        exit 1
    elif [ ! -d $OUTPUT_DIR ]; then
        echo "directory not found: ${OUTPUT_DIR}" 1>&2
        exit 1
    elif [ ! -d $LIB_DIR ]; then
        echo "directory not found: ${LIB_DIR}" 1>&2
        exit 1
    fi

    # create the result directory if it does not exist
    mkdir -p "$DATA_DIR"
    mkdir -p "$OUT_DIR"

    . "${LIB_DIR}/runtime.sh"
    . "${LIB_DIR}/benchmarks.sh"

    local baseline_system=get_racket_runtime
    local static_system=get_typed_racket_runtime
    local dynamic_system=get_racket_runtime

    if [ ! -d $TMP_DIR ]; then
        # copying the benchmarks to a temporary directory
        cp -r ${SRC_DIR} ${TMP_DIR}
        mkdir -p "$TMP_DIR/partial"

        # logging
        printf "Date\t\t:%s\n" "$DATE" >> "$PARAMS_LOG"
        MYEMAIL="`id -un`@`hostname -f`"
        printf "Machine\t\t:%s\n" "$MYEMAIL" >> "$PARAMS_LOG"
        # grift_ver=$(git rev-parse HEAD)
        # printf "Grift ver.\t:%s\n" "$grift_ver" >> "$PARAMS_LOG"
        clang_ver=$(clang --version | sed -n 's/clang version \([0-9]*.[0-9]*.[0-9]*\) .*/\1/p;q')
        printf "Clang ver.\t:%s\n" "$clang_ver" >> "$PARAMS_LOG"
        gambit_ver=$(gambitc -v | sed -n 's/v\([0-9]*.[0-9]*.[0-9]*\) .*/\1/p;q')
        printf "Gambit ver.\t:%s\n" "$gambit_ver" >> "$PARAMS_LOG"
        racket_ver=$(racket -v | sed -n 's/.* v\([0-9]*.[0-9]*\).*/\1/p;q')
        printf "Racket ver.\t:%s\n" "$racket_ver" >> "$PARAMS_LOG"
        chezscheme_ver=$(chez-scheme --version 2>&1)
        printf "ChezScheme ver.\t:%s\n" "$chezscheme_ver" >> "$PARAMS_LOG"
        printf "loops:\t\t:%s\n" "$LOOPS" >> "$PARAMS_LOG"
    fi

    run_experiment $baseline_system $static_system $dynamic_system

    echo "done."
}

main "$@"
