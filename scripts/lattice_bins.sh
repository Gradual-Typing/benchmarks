#!/bin/sh

set -euo pipefail
declare -r PRECISION=5
TIMEFORMAT=%R

# needed for the fft benchmarks
ulimit -s unlimited

# needed so that anyone can access the files
umask 000

# $1 - baseline system
# $2 - logfile index
# $3 - $path
# $4 - space-separated benchmark arguments
# $5 - disk aux name
# $RETURN - number of configurations
run_config()
{
    local baseline_system="$1"; shift
    local i="$1";               shift
    local path="$1";            shift
    local input_file="$1";      shift
    local disk_aux_name="$1";   shift

    local name=$(basename "$path")
    local logfile="${DATA_DIR}/${name}${disk_aux_name}${i}.log"
    local cache_file="${TMP_DIR}/static/${name}${disk_aux_name}${i}.cache"
    local bs=$(find "$path" -name "*.o$i")
    if [ -f $cache_file ]; then
        RETURN=$(cat "$cache_file")
    else
        local n=0 b
        $baseline_system "$name" "$input_file" "$disk_aux_name"
        local baseline="$RETURN"
        if [ "$CAST_PROFILER" = true ]; then
            echo "name,precision,time,slowdown,speedup,total values allocated,total casts,longest proxy chain,total proxies accessed,total uses,function total values allocated,vector total values allocated,ref total values allocated,tuple total values allocated,function total casts,vector total casts, ref total casts,tuple total casts,function longest proxy chain,vector longest proxy chain,ref longest proxy chain,tuple longest proxy chain,function total proxies accessed,vector total proxies accessed,ref total proxies accessed,tuple total proxies accessed,function total uses,vector total uses,ref total uses,tuple total uses,injects casts,projects casts"\
                 > "$logfile"
        else
            echo "name,precision,time,slowdown,speedup" > "$logfile"
        fi
        for b in $(find "$path" -name "*.o$i"); do
            let n=n+1
            local binpath="${b%.*}"
            local p=$(sed -n 's/;; \([0-9]*.[0-9]*\)%/\1/p;q' \
                          < "${binpath}.grift")
            local sample_index="$(basename $binpath)"
            local bname="$(basename $b)"
            local input="${INPUT_DIR}/${name}/${input_file}"

            avg "$b" "$input"\
                "static" "${OUTPUT_DIR}/static/${name}/${input_file}"\
                "${b}.runtimes"
            local t="$RETURN"
            local speedup=$(echo "${baseline}/${t}" | \
                                bc -l | \
                                awk -v p="$PRECISION" '{printf "%.*f\n", p,$0}')
            local slowdown=$(echo "${t}/${baseline}" | \
                                 bc -l | \
                                 awk -v p="$PRECISION" '{printf "%.*f\n", p,$0}')
            echo $n $b $speedup
            printf "%s,%.2f,%.${PRECISION}f,%.${PRECISION}f,%.${PRECISION}f" \
                   $sample_index $p $t $slowdown $speedup >> "$logfile"

            if [ "$CAST_PROFILER" = true ] ; then
                # run the cast profiler
                eval "cat ${input} | ${b}.prof.o" > /dev/null 2>&1
                mv "$bname.prof.o.prof" "${b}.prof"
                printf "," >> "$logfile"
                # ignore first and last rows and sum the values across all
                # columns in the profile into one column and transpose it into
                # a row
                sed '1d;$d' "${b}.prof" | awk -F, '{print $2+$3+$4+$5+$6+$7}'\
                    | paste -sd "," - | xargs echo -n >> "$logfile"
                echo -n "," >> "$logfile"
                # ignore the first row and the first column and stitsh together
                # all rows into one row
                sed '1d;$d' "${b}.prof" | cut -f1 -d"," --complement\
                    | awk -F, '{print $1","$2","$3","$4}' | paste -sd "," -\
                    | xargs echo -n >> "$logfile"
                echo -n "," >> "$logfile"
                # writing injections
                sed '1d;$d' "${b}.prof" | cut -f1 -d"," --complement\
                    | awk -F, 'FNR == 2 {print $5}' | xargs echo -n >> "$logfile"
                echo -n "," >> "$logfile"
                # writing projections
                sed '1d;$d' "${b}.prof" | cut -f1 -d"," --complement\
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
# $6  - $path
# $7  - space-separated benchmark arguments
# $8  - output of dynamizer
# $9  - printed name of the benchmark
# $10 - disk aux name
gen_output()
{
    local baseline_system="$1"; shift
    local static_system="$1";   shift
    local dynamic_system="$1";  shift
    local c1="$1";              shift
    local c2="$1";              shift
    local path="$1";            shift
    local input_file="$1";      shift
    local disk_aux_name="$1";   shift

    local name=$(basename "$path")
    local logfile1="${DATA_DIR}/${name}${disk_aux_name}${c1}.log"
    local logfile2="${DATA_DIR}/${name}${disk_aux_name}${c2}.log"

    run_config $baseline_system "$c1" "$path" "$input_file" "$disk_aux_name"
    run_config $baseline_system "$c2" "$path" "$input_file" "$disk_aux_name"
    local n="$RETURN"

    $static_system "$name" "$input_file" "$disk_aux_name"
    $dynamic_system "$name" "$input_file" "$disk_aux_name"

    speedup_geometric_mean "$logfile1"
    g1="$RETURN"

    speedup_geometric_mean "$logfile2"
    g2="$RETURN"

    printf "geometric means %s:\t\t%d=%.4f\t%d=%.4f\n" $name $c1 $g1 $c2 $g2

    racket ${LIB_DIR}/csv-set.rkt --add "$name , $c1 , $g1"\
           --add "$name , $c2 , $g2"\
           --in "$GMEANS" --out "$GMEANS"
}

# $1  - baseline system
# $2  - statically typed system
# $3  - dynamically typed system
# $4  - first config index
# $5  - second config index
# $6  - benchmark filename without extension
# $7  - space-separated benchmark arguments
# $8  - nsamples
# $9  - nbins
# $10 - aux name
run_benchmark()
{
    local baseline_system="$1"; shift
    local static_system="$1";   shift
    local dynamic_system="$1";  shift
    local c1="$1";              shift
    local c2="$1";              shift
    local name="$1";            shift
    local input_file="$1";  shift
    local nsamples="$1";        shift
    local nbins="$1";           shift
    local aux_name="$1";        shift

    local lattice_path="${TMP_DIR}/partial/${name}"
    local benchmarks_path="${TMP_DIR}/static"
    local static_source_file="${benchmarks_path}/${name}.grift"
    local dyn_source_file="${TMP_DIR}/dyn/${name}.grift"

    local disk_aux_name="" print_aux_name=""
    if [[ ! -z "${aux_name}" ]]; then
        disk_aux_name="_${aux_name}"
        print_aux_name=" (${aux_name})"
    fi

    local benchmark_args_file="${TMP_DIR}/${name}${disk_aux_name}.args"
    local input="$(cat ${INPUT_DIR}/${name}/${input_file})"
    if [ -f benchmark_args_file ]; then
        local old_input=$(cat "$benchmark_args_file")
        if [ ! $old_input == $input ]; then
            echo "input changed mid test" 1>&2
            exit 1
        fi
    else
        printf "Benchmark\t:%s\n" "$name" >> "$PARAMS_LOG"
        printf "Args\t\t:%s\n" "$input" >> "$PARAMS_LOG"
        echo "$input" > "$benchmark_args_file"
    fi

    local lattice_file="${lattice_path}/out"
    local dynamizer_out=""

    if [ -f "$lattice_file" ]; then
        dynamizer_out=$(cat "$lattice_file")
    else
        rm -rf "$lattice_path"
        rm -f "${lattice_path}.grift"
        cp "$static_source_file" "${lattice_path}.grift"

        dynamizer_out=""
        if [ "$LEVEL" = "fine" ]; then
            dynamizer_out=$(dynamizer "${lattice_path}.grift"\
                                      --samples "$nsamples" --bins "$nbins" | \
                                sed -n 's/.* \([0-9]\+\) .* \([0-9]\+\) .*/\1 \2/p')
        else
            dynamizer_out=$(dynamizer "${lattice_path}.grift"\
                                      --coarse 10 | \
                                sed -n 's/.* \([0-9]\+\) .* \([0-9]\+\) .*/\1 \2/p')
        fi
        echo "$dynamizer_out" > "$lattice_file"
    fi

    # check for/create/annotate 100% and 0%
    local benchmark_100_file="${lattice_path}/static.grift"
    if [ ! -f benchmark_100_file ]; then
        cp "$static_source_file" "$benchmark_100_file"
        sed -i '1i;; 100.00%' "$benchmark_100_file"
    fi
    local benchmark_0_file="${lattice_path}/dyn.grift"
    if [ ! -f benchmark_0_file ]; then
        cp "$dyn_source_file" "$benchmark_0_file"
        sed -i '1i;; 0.0%' "$benchmark_0_file"
    fi

    if [ "$CAST_PROFILER" = true ] ; then
        grift-bench --cast-profiler -j 4 -s "$c1 $c2" "${lattice_path}/"
    else
        grift-bench -s "$c1 $c2" "${lattice_path}/"
    fi

    gen_output $baseline_system $static_system $dynamic_system $c1 $c2\
               "$lattice_path" "$input_file" "$disk_aux_name"
}

# $1 - baseline system
# $2 - statically typed system
# $3 - dynamically typed system
# $4 - first config index
# $5 - second config index
# $6 - nsamples
# $7 - nbins
run_experiment()
{
    local baseline_system="$1"; shift
    local static_system="$1";   shift
    local dynamic_system="$1";  shift
    local c1="$1";              shift
    local c2="$1";              shift
    local nsamples="$1";        shift
    local nbins="$1";           shift

    local g=()

    for ((i=0;i<${#BENCHMARKS[@]};++i)); do
        run_benchmark $baseline_system $static_system $dynamic_system $c1 $c2\
                      "${BENCHMARKS[i]}" "${BENCHMARKS_ARGS_LATTICE[i]}"\
                      "$nsamples" "$nbins" ""
        g+=($RETURN)
    done

    IFS=$'\n'
    max=$(echo "${g[*]}" | sort -nr | head -n1)
    min=$(echo "${g[*]}" | sort -n | head -n1)

    echo "finished experiment comparing" $c1 "vs" $c2 \
         ", where speedups range from " $min " to " $max
}

main()
{
    USAGE="Usage: $0 [fine|coarse] nsamples nbins loops cast_profiler? root [fresh|date] n_1,n_2 ... n_n"
    if [ "$#" == "0" ]; then
        echo "$USAGE"
        exit 1
    fi
    local LEVEL="$1";    shift
    local nsamples="$1"; shift
    local nbins="$1";    shift
    LOOPS="$1";          shift
    CAST_PROFILER="$1";  shift
    ROOT_DIR="$1";       shift
    local date="$1";     shift

    declare -r LB_DIR="${ROOT_DIR}/lattice_bins"
    if [ "$date" == "fresh" ]; then
        declare -r DATE=`date +%Y_%m_%d_%H_%M_%S`
        mkdir -p "$LB_DIR/$DATE"
    elif [ "$date" == "test" ]; then
        declare -r DATE="test"
        if [ ! -d "$LB_DIR/$DATE" ]; then
            mkdir -p "$LB_DIR/$DATE"
        fi
    else
        declare -r DATE="$date"
        if [ ! -d "$LB_DIR/$DATE" ]; then
            echo "$LB_DIR/$DATE" "Directory not found"
            exit 1
        fi
    fi

    declare -r EXP_DIR="$LB_DIR/$DATE"
    declare -r DATA_DIR="$EXP_DIR/data"
    declare -r OUT_DIR="$EXP_DIR/output"
    declare -r GMEANS="${OUT_DIR}/geometric-means.csv"
    declare -r TMP_DIR="$EXP_DIR/tmp"
    declare -r SRC_DIR="${ROOT_DIR}/src"
    declare -r INPUT_DIR="${ROOT_DIR}/inputs"
    declare -r OUTPUT_DIR="${ROOT_DIR}/outputs"
    declare -r LIB_DIR="${ROOT_DIR}/scripts/lib"
    declare -r PARAMS_LOG="$EXP_DIR/params.txt"

    # Check to see if all is right in the world
    if [ ! -d $ROOT_DIR ]; then
        echo "directory not found: ${ROOT_DIR}" 1>&2
        exit 1
    elif [ ! -d $EXP_DIR ]; then
        echo "Directory not found: ${EXP_DIR}"
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
        cp -r ${SRC_DIR} $TMP_DIR
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
        printf "nsamples\t:%s\n" "$nsamples" >> "$PARAMS_LOG"
        printf "nbins\t:%s\n" "$nbins" >> "$PARAMS_LOG"
    fi

    local i j
    if [ "$#" == "1" ]; then
        local config="$1";   shift
        for i in `seq ${config}`; do
            for j in `seq ${i} ${config}`; do
                if [ ! $i -eq $j ]; then
                    run_experiment $baseline_system $static_system \
                                   $dynamic_system $i $j $nsamples $nbins
                fi
            done
        done
    else
        while (( "$#" )); do
            i=$1; shift
            j=$1; shift
            run_experiment $baseline_system $static_system $dynamic_system $i\
                           $j $nsamples $nbins
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
