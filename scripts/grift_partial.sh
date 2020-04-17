#!/bin/sh

set -euo pipefail
declare -r PRECISION=5
TIMEFORMAT=%R

# needed so that anyone can access the files
umask 000

# $1 - baseline system
# $2 - configuration index
# $3 - directory path of the samples, it should have the binaries. Also, the
#      directory name is the same as the benchmark name
# $4 - space-separated benchmark arguments
# $5 - disk aux name
# $RETURN - number of configurations
run_config()
{
    local baseline_system="$1";        shift
    local config_index="$1";           shift
    local samples_directory_path="$1"; shift
    local input_filename="$1";         shift
    local disk_aux_name="$1";          shift

    local name=$(basename "$samples_directory_path")
    local logfile="${DATA_DIR}/${name}${disk_aux_name}${config_index}.log"
    local cache_file="${TMP_DIR}/static/${name}${disk_aux_name}${config_index}.cache"

    if [ -f $cache_file ]; then
        RETURN=$(cat "$cache_file")
    else
        local n=0 b
        $baseline_system "$name" "$input_filename" "$disk_aux_name"
        local baseline="$RETURN"
        if [ "$CAST_PROFILER" = true ]; then
            echo "name,precision,time,slowdown,speedup,total values allocated,total casts,longest proxy chain,total proxies accessed,total uses,function total values allocated,vector total values allocated,ref total values allocated,tuple total values allocated,function total casts,vector total casts, ref total casts,tuple total casts,function longest proxy chain,vector longest proxy chain,ref longest proxy chain,tuple longest proxy chain,function total proxies accessed,vector total proxies accessed,ref total proxies accessed,tuple total proxies accessed,function total uses,vector total uses,ref total uses,tuple total uses,injects casts,projects casts"\
                 > "$logfile"
        else
            echo "name,precision,time,slowdown,speedup" > "$logfile"
        fi
        for sample_path in $(find "$samples_directory_path" -name "*.o${config_index}"); do
            let n=n+1
            local sample_path_without_extension="${sample_path%.*}"
            local p=$(sed -n 's/;; \([0-9]*.[0-9]*\)%/\1/p;q' \
                          < "${sample_path_without_extension}.grift")
            local sample_number="$(basename $sample_path_without_extension)"
            local sample_bin_filename="$(basename $sample_path)"
            local input_filepath="${INPUT_DIR}/${name}/${input_filename}"

            avg "$sample_path" "$input_filepath"\
                "static" "${OUTPUT_DIR}/static/${name}/${input_filename}"\
                "${sample_path}.runtimes"
            local t="$RETURN"
            local speedup=$(echo "${baseline}/${t}" | \
                                bc -l | \
                                awk -v p="$PRECISION" '{printf "%.*f\n", p,$0}')
            local slowdown=$(echo "${t}/${baseline}" | \
                                 bc -l | \
                                 awk -v p="$PRECISION" '{printf "%.*f\n", p,$0}')
            echo $n $sample_path $speedup
            printf "%s,%.2f,%.${PRECISION}f,%.${PRECISION}f,%.${PRECISION}f" \
                   $sample_number $p $t $slowdown $speedup >> "$logfile"

            if [ "$CAST_PROFILER" = true ] ; then
                # run the cast profiler
                eval "cat ${input_filepath} | ${sample_path}.prof.o" > /dev/null 2>&1
                mv "$sample_bin_filename.prof.o.prof" "${sample_path}.prof"
                printf "," >> "$logfile"
                # ignore first and last rows and sum the values across all
                # columns in the profile into one column and transpose it into
                # a row
                sed '1d;$d' "${sample_path}.prof" | awk -F, '{print $2+$3+$4+$5+$6+$7}'\
                    | paste -sd "," - | xargs echo -n >> "$logfile"
                echo -n "," >> "$logfile"
                # ignore the first row and the first column and stitsh together
                # all rows into one row
                sed '1d;$d' "${sample_path}.prof" | cut -f1 -d"," --complement\
                    | awk -F, '{print $1","$2","$3","$4}' | paste -sd "," -\
                    | xargs echo -n >> "$logfile"
                echo -n "," >> "$logfile"
                # writing injections
                sed '1d;$d' "${sample_path}.prof" | cut -f1 -d"," --complement\
                    | awk -F, 'FNR == 2 {print $5}' | xargs echo -n >> "$logfile"
                echo -n "," >> "$logfile"
                # writing projections
                sed '1d;$d' "${sample_path}.prof" | cut -f1 -d"," --complement\
                    | awk -F, 'FNR == 2 {print $6}' >> "$logfile"
            else
                printf "\n" >> "$logfile"
            fi
        done
        RETURN="$n"
        echo "$RETURN" > "$cache_file"
    fi
}

# $1  - baseline system
# $2  - statically typed system
# $3  - dynamically typed system
# $4  - first config index
# $5  - second config index
# $6  - $samples_directory_path
# $7  - space-separated benchmark arguments
# $8  - output of dynamizer
# $9  - printed name of the benchmark
# $10 - disk aux name
gen_output()
{
    local baseline_system="$1";        shift
    local static_system="$1";          shift
    local dynamic_system="$1";         shift
    local config1_index="$1";          shift
    local config2_index="$1";          shift
    local samples_directory_path="$1"; shift
    local input_filename="$1";         shift
    local disk_aux_name="$1";          shift

    local name=$(basename "$samples_directory_path")
    local logfile1="${DATA_DIR}/${name}${disk_aux_name}${config1_index}.log"
    local logfile2="${DATA_DIR}/${name}${disk_aux_name}${config2_index}.log"

    run_config $baseline_system "$config1_index" "$samples_directory_path" "$input_filename" "$disk_aux_name"
    run_config $baseline_system "$config2_index" "$samples_directory_path" "$input_filename" "$disk_aux_name"

    $static_system "$name" "$input_filename" "$disk_aux_name"
    $dynamic_system "$name" "$input_filename" "$disk_aux_name"

    speedup_geometric_mean "$logfile1"
    g1="$RETURN"

    speedup_geometric_mean "$logfile2"
    g2="$RETURN"

    printf "geometric means %s:\t\t%d=%.4f\t%d=%.4f\n" $name $config1_index $g1 $config2_index $g2

    racket ${LIB_DIR}/csv-set.rkt --add "$name , $config1_index , $g1"\
           --add "$name , $config2_index , $g2"\
           --in "$GMEANS" --out "$GMEANS"
}

# $1  - baseline system
# $2  - statically typed system
# $3  - dynamically typed system
# $4  - first config index
# $5  - second config index
# $6  - benchmark filename without extension
# $7  - space-separated benchmark arguments
# $8 - aux name
run_benchmark()
{
    local baseline_system="$1"; shift
    local static_system="$1";   shift
    local dynamic_system="$1";  shift
    local config1_index="$1";   shift
    local config2_index="$1";   shift
    local benchmark_name="$1";  shift
    local input_filename="$1";  shift
    local aux_name="$1";        shift

    local samples_directory_path="${TMP_DIR}/partial/${benchmark_name}"
    local static_source_path="${TMP_DIR}/static/${benchmark_name}.grift"
    if [ "$MODE" = "fine" ]; then
	static_source_path="${TMP_DIR}/static/${benchmark_name}/single/${benchmark_name}.grift"
    else
	static_source_path="${TMP_DIR}/static/${benchmark_name}/modules"
    fi
    local dyn_source_file="${TMP_DIR}/dyn/${benchmark_name}.grift"

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

    local lattice_file="${samples_directory_path}/out"
    local dynamizer_out=""

    if [ -f "$lattice_file" ]; then
        dynamizer_out=$(cat "$lattice_file")
    else
        rm -rf "$samples_directory_path"

        dynamizer_out=""
        if [ "$MODE" = "fine" ]; then
	    rm -f "${samples_directory_path}.grift"
            cp "$static_source_path" "${samples_directory_path}.grift"
	    dynamizer_out=$(dynamizer "${samples_directory_path}.grift" \
				      --fine\
				      --configurations-count "$SAMPLES_N"\
				      --bins "$BINS_N" | \
                            sed -n 's/.* \([0-9]\+\) .* \([0-9]\+\) .*/\1 \2/p')

	    # check for/create/annotate 100% and 0%
	    local benchmark_100_file="${samples_directory_path}/static.grift"
	    if [ ! -f benchmark_100_file ]; then
		cp "$static_source_path" "$benchmark_100_file"
		sed -i '1i;; 100.00%' "$benchmark_100_file"
	    fi
	    local benchmark_0_file="${samples_directory_path}/dyn.grift"
	    if [ ! -f benchmark_0_file ]; then
		cp "$dyn_source_file" "$benchmark_0_file"
		sed -i '1i;; 0.0%' "$benchmark_0_file"
	    fi
        else
            cp -a "$static_source_path/." "${TMP_DIR}/partial/"
            dynamizer_out=$(dynamizer "${TMP_DIR}/partial/main.grift"\
                                      --coarse | \
                            sed -n 's/.* \([0-9]\+\) .* \([0-9]\+\) .*/\1 \2/p')
	    # the source is created by the dynamizer
	    mv "${TMP_DIR}/partial/main" "${samples_directory_path}"
	    # deleting the source files so it does not mingle with sources of
	    # other benchmarks where modules might happen to share the same name
	    rm "${TMP_DIR}/partial/"*.grift
        fi
        echo "$dynamizer_out" > "$lattice_file"
    fi

    # Compile the samples
    if [ "$CAST_PROFILER" = true ] ; then
        grift-bench --cast-profiler -j 4 -s "$config1_index $config2_index" "${samples_directory_path}/"
    else
        grift-bench -s "$config1_index $config2_index" "${samples_directory_path}/"
    fi

    gen_output $baseline_system $static_system $dynamic_system $config1_index $config2_index\
               "$samples_directory_path" "$input_filename" "$disk_aux_name"
}

# $1 - baseline system
# $2 - statically typed system
# $3 - dynamically typed system
# $4 - first config index
# $5 - second config index
run_experiment()
{
    local baseline_system="$1"; shift
    local static_system="$1";   shift
    local dynamic_system="$1";  shift
    local config1_index="$1";   shift
    local config2_index="$1";   shift

    local g=()

    if [ "$INPUT_TYPE" == "test" ]; then
	    for ((i=0;i<${#BENCHMARKS[@]};++i)); do
		run_benchmark $baseline_system $static_system $dynamic_system $config1_index $config2_index\
                      "${BENCHMARKS[i]}" "${BENCHMARKS_ARGS_TRIVIAL[i]}" ""
		g+=($RETURN)
	    done
    elif [ "$INPUT_TYPE" == "release" ]; then
	if [ "$MODE" = "fine" ]; then
	    for ((i=0;i<${#BENCHMARKS[@]};++i)); do
		run_benchmark $baseline_system $static_system $dynamic_system $config1_index $config2_index\
                      "${BENCHMARKS[i]}" "${BENCHMARKS_ARGS_PARTIAL_FINE[i]}" ""
		g+=($RETURN)
	    done
	elif [ "$MODE" = "coarse" ]; then
	    for ((i=0;i<${#BENCHMARKS[@]};++i)); do
		run_benchmark $baseline_system $static_system $dynamic_system $config1_index $config2_index\
                      "${BENCHMARKS[i]}" "${BENCHMARKS_ARGS_PARTIAL_COARSE[i]}" ""
		g+=($RETURN)
	    done
	fi
    else
	echo "ERROR: INPUT_TYPE: expected test or release but got ${INPUT_TYPE}"
	exit 1
    fi

    IFS=$'\n'
    max=$(echo "${g[*]}" | sort -nr | head -n1)
    min=$(echo "${g[*]}" | sort -n | head -n1)

    echo "finished experiment comparing" $config1_index "vs" $config2_index \
         ", where speedups range from " $min " to " $max
}

main()
{
    USAGE="Usage: $0 root loops [fresh|date] cast_profiler? [fine|coarse] BINS_N SAMPLES_N INPUT_TYPE n_1,n_2 ... n_n"
    if [ "$#" == "0" ]; then
        echo "$USAGE"
        exit 1
    fi

    ROOT_DIR="$1";      shift
    LOOPS="$1";         shift
    local date="$1";    shift
    CAST_PROFILER="$1"; shift
    MODE="$1";          shift
    BINS_N="$1";        shift
    SAMPLES_N="$1";     shift
    INPUT_TYPE="$1";    shift
    OVERWRITE="$1";     shift

    declare -r RESULTS_DIR="${ROOT_DIR}/results/grift/partial/${MODE}"
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
    rm -f $GMEANS
    touch $GMEANS

    . "${LIB_DIR}/runtime.sh"
    . "${LIB_DIR}/benchmarks.sh"

    local baseline_system=get_racket_runtime
    local static_system=get_static_grift_runtime
    local dynamic_system=get_dyn_grift_17_runtime

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
        printf "BINS_N\t:%s\n" "$BINS_N" >> "$PARAMS_LOG"
    fi

    local i j
    if [ "$#" == "1" ]; then
        local config="$1";   shift
        for i in `seq ${config}`; do
            for j in `seq ${i} ${config}`; do
                if [ ! $i -eq $j ]; then
                    run_experiment $baseline_system $static_system \
                                   $dynamic_system $i $j
                fi
            done
        done
    else
        while (( "$#" )); do
            i=$1; shift
            j=$1; shift
            run_experiment $baseline_system $static_system $dynamic_system $i $j
        done
    fi

    racket ${LIB_DIR}/csv-set.rkt -i $GMEANS --config-names 1 \
           --si 2 \
           -o ${OUT_DIR}/gm-total.csv
    racket ${LIB_DIR}/csv-set.rkt -i $GMEANS --config-names 1 \
           --si 2 --su 0 \
           -o ${OUT_DIR}/gm-benchmart.csv
    racket ${LIB_DIR}/csv-set.rkt -i $GMEANS --config-names 1 \
           --si 2 --su 1 \
           -o ${OUT_DIR}/gm-config.csv

    echo "done."
}

main "$@"
