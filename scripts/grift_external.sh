#!/bin/sh
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

declare -r PRECISION=5
TIMEFORMAT=%R

# needed so that anyone can access the files
umask 000

# $1 - baseline system
# $2 - benchmark filename without extension
# $3 - space-separated benchmark arguments
# $4 - aux name
# $5 - static/dyn/partial
# $6 - logfile full path
write_grift_runtimes_and_slowdowns()
{
    local baseline_system="$1";   shift
    local name="$1";              shift
    local benchmark_args="$1";    shift
    local disk_aux_name="$1";     shift
    local mode="$1";              shift # static or dyn
    local runtimes_logfile="$1";  shift
    local slowdowns_logfile="$1"; shift

    local benchmark_path=""
    if [ "$mode" = "static" ]; then
	benchmark_path="${TMP_DIR}/${mode}/${name}/single/${name}"
    elif [ "$mode" = "dyn" ]; then
	benchmark_path="${TMP_DIR}/${mode}/${name}"
    else
	echo "invalid mode: ${mode}"
	exit -1
    fi

    for config_index in ${CONFIGS[@]}; do
        get_grift_runtime "$benchmark_path" "$benchmark_args" "$disk_aux_name" \
			  $config_index
        printf ",$RETURN" >> $runtimes_logfile
	get_grift_slowdown $baseline_system "$benchmark_path" "$benchmark_args" \
			  "$disk_aux_name" $config_index
	printf ",$RETURN" >> $slowdowns_logfile
        echo "grift $config_index slowdown: $RETURN"
    done
}

# $1 - static baseline system
# $2 - dynamic baseline system
# $3 - benchmark filename without extension
# $4 - space-separated benchmark arguments
# $5 - aux name
run_benchmark()
{
    local baseline_system_static="$1";  shift
    local baseline_system_dynamic="$1"; shift
    local name="$1";                    shift
    local input_file="$1";              shift
    local aux_name="$1";                shift

    local runtimes_static_logfile="${DATA_DIR}/static_runtimes.log"
    local runtimes_dynamic_logfile="${DATA_DIR}/dyn_runtimes.log"
    local runtimes_partial_logfile="${DATA_DIR}/partial_runtimes.log"
    local slowdowns_static_logfile="${DATA_DIR}/static_slowdowns.log"
    local slowdowns_dynamic_logfile="${DATA_DIR}/dyn_slowdowns.log"
    local slowdowns_partial_logfile="${DATA_DIR}/partial_slowdowns.log"

    local disk_aux_name="" print_aux_name=""
    if [[ ! -z "${aux_name}" ]]; then
        disk_aux_name="_${aux_name}"
        print_aux_name="(${aux_name})"
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

    # Record the runtime of Statically Typed Varients
    printf "$name$print_aux_name" >> "$runtimes_static_logfile"
    printf "$name$print_aux_name" >> "$slowdowns_static_logfile"
    write_grift_runtimes_and_slowdowns $baseline_system_static "$name" "$input_file"\
                         "$disk_aux_name" static "$runtimes_static_logfile" "$slowdowns_static_logfile"
    # Typed Racket
    printf "Typed Racket slowdown: "
    get_typed_racket_runtime "$name" "$input_file" "$disk_aux_name"
    printf ",$RETURN" >> $runtimes_static_logfile
    get_slowdown typed_racket $baseline_system_static\
                "$name" "$input_file" "$disk_aux_name"
    printf ",$RETURN" >> $slowdowns_static_logfile
    echo "Typed Racket slowdown: $RETURN"
    
    # OCaml
    get_ocaml_runtime "$name" "$input_file" "$disk_aux_name"
    printf ",$RETURN" >> $runtimes_static_logfile
    get_slowdown ocaml $baseline_system_static\
                 "$name" "$input_file" "$disk_aux_name"
    printf ",$RETURN" >> $slowdowns_static_logfile
    echo "OCaml slowdown: $RETURN"

    
    printf "\n" >> "$runtimes_static_logfile"
    printf "\n" >> "$slowdowns_static_logfile"
    printf "$name$print_aux_name" >> $runtimes_dynamic_logfile
    printf "$name$print_aux_name" >> $slowdowns_dynamic_logfile
    
    write_grift_runtimes_and_slowdowns $baseline_system_dynamic "$name" "$input_file"\
                         "$disk_aux_name" dyn "$runtimes_dynamic_logfile" "$slowdowns_dynamic_logfile"

    # Gambit
    get_gambit_runtime "$name" "$input_file" "$disk_aux_name"
    printf ",$RETURN" >> $runtimes_dynamic_logfile
    get_slowdown gambit $baseline_system_dynamic\
                "$name" "$input_file" "$disk_aux_name"
    printf ",$RETURN" >> $slowdowns_dynamic_logfile
    echo "Gambit Slowdown: $RETURN"
    
    get_chezscheme_runtime "$name" "$input_file" "$disk_aux_name"
    printf ",$RETURN" >> $runtimes_dynamic_logfile
    get_slowdown chezscheme $baseline_system_dynamic\
                "$name" "$input_file" "$disk_aux_name"
    printf ",$RETURN" >> $slowdowns_dynamic_logfile
    echo "Chez slowdown: $RETURN"
    
    printf "\n" >> "$runtimes_dynamic_logfile"
    printf "\n" >> "$slowdowns_dynamic_logfile"

    echo "finished ${name}${print_aux_name}"
}

# $1 - static or dyn
gen_static_fig()
{
    local mode="static"
    local sys="$1";  shift
    local outfile_name="$1"; shift
    local key_position="$1"; shift
    local ymin="$1"; shift
    local ymax="$1"; shift

    local runtimes_logfile="${DATA_DIR}/${mode}_runtimes.log"
    local slowdowns_logfile="${DATA_DIR}/${mode}_slowdowns.log"
    local outfile="${OUT_DIR}/${outfile_name}.png"
    local self_outfile="${OUT_DIR}/${outfile_name}_self.png"
    local N=$(head -1 "${runtimes_logfile}" | sed 's/[^,]//g' | wc -c)

    rm -rf "$outfile"
    
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,960"`
            `" noenhanced color font 'Verdana,26' ;"`
            `"set output '${outfile}';"`
                `"set border 15 back;"`
            `"set key font 'Verdana,20';"`
            `"set style data histogram;"`
            `"set style histogram cluster gap 1;"`
            `"set style fill pattern border -1;"`
            `"load '${LIB_DIR}/dark-colors.pal';"`
            `"set boxwidth 0.9;"` 
            `"set ylabel \" Runtime in seconds\";"`
            `"set title \"\";"`
            `"set xtic rotate by -45 scale 0;"`
            `"set grid ytics;"`
            `"plot '${runtimes_logfile}' using 2:xtic(1) title col,"`
            `"  for [i=3:$N] \"\" "`
            `"using i title columnheader(i) ls (i-1)"

    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,960"`
            `" noenhanced color font 'Verdana,26' ;"`
            `"set output '${self_outfile}';"`
            `"set border 15 back;"`
            `"set yrange [0:2];"`
            `"set key font 'Verdana,20';"`
            `"set style data histogram;"`
            `"set style histogram cluster gap 1;"`
            `"set style fill pattern border -1;"`
            `"load '${LIB_DIR}/dark-colors.pal';"`
            `"set boxwidth 0.9;"` 
            `"set ylabel \"  Slowdown with respect to ${sys}\";"`
            `"set title \"\";"`
            `"set xtic rotate by -45 scale 0;"`
            `"set grid ytics;"`
            `"set ytics add (\"1\" 1);"`
            `"plot '${slowdowns_logfile}' using 2:xtic(1) title col,"`
            `"  for [i=3:4] \"\" "`
            `"using i title columnheader(i) ls (i-1)"
}

# $1 - static or dyn
gen_dynamic_fig()
{
    local mode="dyn"
    local sys="$1";  shift
    local outfile_name="$1"; shift
    local key_position="$1"; shift
    local ymin="$1"; shift
    local ymax="$1"; shift

    local runtimes_logfile="${DATA_DIR}/${mode}_runtimes.log"
    local slowdowns_logfile="${DATA_DIR}/${mode}_slowdowns.log"
    local outfile="${OUT_DIR}/${outfile_name}.png"
    local self_outfile="${OUT_DIR}/${outfile_name}_self.png"
    local N=$(head -1 "${runtimes_logfile}" | sed 's/[^,]//g' | wc -c)

    rm -rf "$outfile"
    
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,960"`
            `" noenhanced color font 'Verdana,26' ;"`
            `"set output '${outfile}';"`
                `"set border 15 back;"`
            `"set key font 'Verdana,20';"`
            `"set style data histogram;"`
            `"set style histogram cluster gap 1;"`
            `"set style fill pattern border -1;"`
            `"load '${LIB_DIR}/dark-colors.pal';"`
            `"set boxwidth 0.9;"` 
            `"set ylabel \" Runtime in seconds\";"`
            `"set title \"\";"`
            `"set xtic rotate by -45 scale 0;"`
            `"set grid ytics;"`
            `"plot '${runtimes_logfile}' using 2:xtic(1) title col,"`
            `"  for [i=3:$N] \"\" "`
            `"using i title columnheader(i) ls (i-1)"

    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,960"`
            `" noenhanced color font 'Verdana,26' ;"`
            `"set output '${self_outfile}';"`
            `"set border 15 back;"`
            `"set yrange [0:3];"`
            `"set key font 'Verdana,20';"`
            `"set style data histogram;"`
            `"set style histogram cluster gap 1;"`
            `"set style fill pattern border -1;"`
            `"load '${LIB_DIR}/dark-colors.pal';"`
            `"set boxwidth 0.9;"` 
            `"set ylabel \"  Slowdown with respect to ${sys}\";"`
            `"set title \"\";"`
            `"set xtic rotate by -45 scale 0;"`
            `"set grid ytics;"`
            `"set ytics add (\"1\" 1);"`
            `"plot '${slowdowns_logfile}' using 2:xtic(1) title col"
}


# $1 - static baseline system
# $2 - dynamic baseline system
run_experiment()
{
    local baseline_system_static="$1";  shift
    local baseline_system_dynamic="$1"; shift
    
    local runtimes_static_logfile="${DATA_DIR}/static_runtimes.log"
    local runtimes_dynamic_logfile="${DATA_DIR}/dyn_runtimes.log"
    local runtimes_partial_logfile="${DATA_DIR}/partial_runtimes.log"
    local slowdowns_static_logfile="${DATA_DIR}/static_slowdowns.log"
    local slowdowns_dynamic_logfile="${DATA_DIR}/dyn_slowdowns.log"
    local slowdowns_partial_logfile="${DATA_DIR}/partial_slowdowns.log"
    
    local configs=( $CONFIGS )
    local configs_len=${#configs[@]}
    
    if [ $configs_len -eq 1 ] 
    then
    local config_str="Grift"
    else
    local config_str=$(grift-configs --name-sep " + " --names $CONFIGS)
    fi    
    
    local shared_str=$(grift-configs --name-sep "_" --common $CONFIGS)
    
    echo "name,${config_str},Typed-Racket,OCaml" > "$runtimes_static_logfile"
    echo "name,${config_str},Gambit,Chez Scheme" > "$runtimes_dynamic_logfile"
    echo "name,${config_str}" > "$runtimes_partial_logfile"
    echo "name,${config_str},Typed-Racket,OCaml" > "$slowdowns_static_logfile"
    echo "name,${config_str},Gambit,Chez Scheme" > "$slowdowns_dynamic_logfile"
    echo "name,${config_str}" > "$slowdowns_partial_logfile"

    for ((i=0;i<${#BENCHMARKS_ARGS_EXTERNAL[@]};++i)); do
	run_benchmark $baseline_system_static $baseline_system_dynamic\
                      "${BENCHMARKS[i]}" "${BENCHMARKS_ARGS_EXTERNAL[i]}" ""
    done

    local gmlog1=$(racket "${LIB_DIR}/geometric-mean.rkt" $slowdowns_static_logfile)
    local gmlog2=$(racket "${LIB_DIR}/geometric-mean.rkt" $slowdowns_dynamic_logfile)
    echo "$gmlog1" > $slowdowns_static_logfile
    echo "$gmlog2" > $slowdowns_dynamic_logfile

    gen_static_fig "Static Grift" "${shared_str}_static" "right" "" ""
    gen_dynamic_fig "Proxied" "${shared_str}_dynamic" "right" "" ""
}

main()
{
    USAGE="Usage: $0 loops root date config_n ..."
    if [ "$#" -le "2" ]; then
        echo "$USAGE"
        exit 1
    fi
    LOOPS="$1";      shift
    ROOT_DIR="$1";   shift
    local date="$1"; shift
    OVERWRITE="$1";  shift
    CONFIGS="$@"

    declare -r EXTERNAL_DIR="${ROOT_DIR}/results/grift/external"
    
    if [ "$date" == "fresh" ]; then
        declare -r DATE=`date +%Y_%m_%d_%H_%M_%S`
    elif [ "$date" == "test" ]; then
        declare -r DATE="test"
    else
        declare -r DATE="$date"
        if [ ! -d "${EXTERNAL_DIR}/$DATE" ]; then
            echo "Directory not found"
            exit 1
        fi
    fi

    declare -r EXP_DIR="${EXTERNAL_DIR}/$DATE"
    declare -r DATA_DIR="$EXP_DIR/data"
    declare -r OUT_DIR="$EXP_DIR/output"
    declare -r TMP_DIR="$EXP_DIR/tmp"
    declare -r SRC_DIR="$ROOT_DIR/src"
    declare -r INPUT_DIR="$ROOT_DIR/inputs"
    declare -r OUTPUT_DIR="$ROOT_DIR/outputs"
    declare -r PARAMS_LOG="$EXP_DIR/params.txt"
    declare -r LIB_DIR="$ROOT_DIR/scripts/lib"

    if [ "$OVERWRITE" = true ]; then
	rm -rf "$EXP_DIR"
	echo "$EXP_DIR has been deleted."
    fi

    # Check to see if all is right in the world
    if [ ! -d $ROOT_DIR ]; then
        echo "test directory not found" 1>&2
        exit 1
    elif [ ! -d $SRC_DIR ]; then
        echo "source directory not found" 1>&2
        exit 1
    elif [ ! -d $INPUT_DIR ]; then
        echo "input directory not found" 1>&2
        exit 1
    elif [ ! -d $OUTPUT_DIR ]; then
        echo "output directory not found" 1>&2
        exit 1
    elif [ ! -d $LIB_DIR ]; then
        echo "lib directory not found" 1>&2
        exit 1
    fi
    
    # create the result directory if it does not exist
    mkdir -p "$DATA_DIR"
    mkdir -p "$OUT_DIR"

    . "${LIB_DIR}/runtime.sh"
    . "${LIB_DIR}/benchmarks.sh"

    if [ ! -d $TMP_DIR ]; then
        # copying the benchmarks to a temporary directory
        cp -r $SRC_DIR $TMP_DIR

        
        
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

    run_experiment get_static_grift_runtime get_dyn_grift_17_runtime
    echo "done."
}

main "$@"
