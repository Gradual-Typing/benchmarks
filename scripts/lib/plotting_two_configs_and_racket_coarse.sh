#!/bin/sh

# needed so that anyone can access the files
umask 000

# runtime.sh and benchmarks.sh should be sourced before calling any of these functions

# arg1: the index of the first configuration
# arg2: the index of the second configuration
# arg3: the index of the configuration to be used to plot the Dynamic Grift line
function plot_two_configs_and_racket_coarse()
{
    local c1="$1";         shift
    local c2="$1";         shift
    local dyn_config="$1"; shift

    color1="$DGREEN"
    color2="$DPURPLE"
    color3="$SYELLOW"

    local config_str=$(grift-configs -c $c1 $c2)
    local c1t=$(echo $config_str | sed -n 's/\(.*\),.*,.*/\1/p;q')
    local c2t=$(echo $config_str | sed -n 's/.*,\(.*\),.*/\1/p;q')
    local ct=$(echo $config_str | sed -n 's/.*,.*,\(.*\)/\1/p;q')

    PLOT_DIR="${OUT_DIR}/${ct}"
    RUNTIMES_DIR="${PLOT_DIR}/runtimes"
    CASTS_DIR="${PLOT_DIR}/casts"
    RUNTIME_AND_CASTS_COUNT_DIR="${PLOT_DIR}/runtime_and_casts_count"
    LONGEST_PROXY_CHAINS_DIR="${PLOT_DIR}/longest_proxy_chains"
    RUNTIME_AND_LONGEST_PROXY_CHAIN_DIR="${PLOT_DIR}/runtime_and_longest_proxy_chain"
    ALL_DIR="${PLOT_DIR}/all"
    CUMULATIVE_PERFORMANCE_DIR="${PLOT_DIR}/cum_perf"

    mkdir -p "$RUNTIMES_DIR"
    mkdir -p "$CASTS_DIR"
    mkdir -p "$RUNTIME_AND_CASTS_COUNT_DIR"
    mkdir -p "$LONGEST_PROXY_CHAINS_DIR"
    mkdir -p "$RUNTIME_AND_LONGEST_PROXY_CHAIN_DIR"
    mkdir -p "$ALL_DIR"
    mkdir -p "$CUMULATIVE_PERFORMANCE_DIR"

    local legend_fig="${CUMULATIVE_PERFORMANCE_DIR}/legend.png"

    gnuplot -e "set datafile separator \",\"; set terminal pngcairo "`
                `"enhanced color font 'Verdana,20' size 1300,80;"`
                `"set output '${legend_fig}';"`
                `"unset border; unset tics;"`
                `"set key horizontal;"`
                `"plot [0:1] [0:1] NaN lc rgb '$color1' lw 3 title '${c1t}',"`
                `"     NaN lc rgb '$color2' lw 3 title '${c2t}',"`
		`"     NaN lc rgb '$color3' lw 3 title 'Typed Racket'"

    for benchmark in "${BENCHMARKS[@]}"; do
	plot_two_configs_and_racket_coarse_benchmark "$benchmark" $c1 $c2 "$c1t" "$c2t" $dyn_config
    done

    convert -append \
	    "${CUMULATIVE_PERFORMANCE_DIR}/quicksort.png" \
	    "${CUMULATIVE_PERFORMANCE_DIR}/sieve.png" \
	    "${CUMULATIVE_PERFORMANCE_DIR}/ray.png" \
	    "${CUMULATIVE_PERFORMANCE_DIR}/blackscholes.png" \
	    "${CUMULATIVE_PERFORMANCE_DIR}/n_body.png" \
	    "${CUMULATIVE_PERFORMANCE_DIR}/fft.png" \
	    "${CUMULATIVE_PERFORMANCE_DIR}/matmult.png" \
	    "$legend_fig" \
	    "${ROOT_DIR}/Fig7_LHS.png"
}

function plot_two_configs_and_racket_coarse_benchmark()
{
    local name="$1";       shift
    local c1="$1";         shift
    local c2="$1";         shift
    local c1t="$1";        shift
    local c2t="$1";        shift
    local dyn_config="$1"; shift

    local runtime_fig="${RUNTIMES_DIR}/${name}.png"
    local casts_count_fig="${CASTS_DIR}/${name}.png"
    local runtime_and_casts_count_fig="${RUNTIME_AND_CASTS_COUNT_DIR}/${name}.png"
    local longest_proxy_chain_fig="${LONGEST_PROXY_CHAINS_DIR}/${name}.png"
    local runtime_and_longest_proxy_chain_fig="${RUNTIME_AND_LONGEST_PROXY_CHAIN_DIR}/${name}.png"
    local all_fig="${ALL_DIR}/${name}.png"
    local cumulative_performance_fig="${CUMULATIVE_PERFORMANCE_DIR}/${name}.png"

    local config1_log="${DATA_DIR}/${name}${c1}.log"
    local config2_log="${DATA_DIR}/${name}${c2}.log"
    local racket_log="${RKT_DATA_DIR}/${name}.log"
    
    local config1_log_sorted="${DATA_DIR}/${name}${c1}.log.sorted"
    local config2_log_sorted="${DATA_DIR}/${name}${c2}.log.sorted"

    if [ ! -f "$config1_log" ]; then
	echo "Warning: log file at path: ${config1_log} is not found"
	return
    fi

    if [ ! -f "$config2_log" ]; then
	echo "Warning: log file at path: ${config2_log} is not found"
	return
    fi

    if [ ! -f "$racket_log" ]; then
	echo "Warning: log file at path: ${racket_log} is not found"
	return
    fi

    # sort log files according to the second column that contains the precentage
    # of typed code and disregard the header row
    tail -n +2 "$config1_log" | sort -k2 -n -t, > "${config1_log_sorted}"
    tail -n +2 "$config2_log" | sort -k2 -n -t, > "${config2_log_sorted}"

    # deletes the first line which contains the fully untyped configuration
    config_name=$(sed -n 1p "${config1_log_sorted}" |cut -d "," -f1)
    if [ "$config_name" = "dyn" ]; then
	sed -i "1d" "${config1_log_sorted}"
	sed -i "1d" "${config2_log_sorted}"
    fi

    print_aux_name=""
    printname="$(echo "$name" | tr _ "-")${print_aux_name}"

    # They are currently unused
    speedup_geometric_mean "$config1_log_sorted"
    config1_speedup_geometric_mean="$RETURN"
    runtime_mean "$config1_log_sorted"
    config1_runtime_mean="$RETURN"

    speedup_geometric_mean "$config2_log_sorted"
    config2_speedup_geometric_mean="$RETURN"
    runtime_mean "$config2_log_sorted"
    config2_runtime_mean="$RETURN"

    dyn_mean=$(cat "${TMP_DIR}/dyn/${name}${disk_aux_name}${dyn_config}.runtime")
    static_mean=$(cat "${TMP_DIR}/static/${name}/single/${name}${disk_aux_name}.static.runtime")

    racket_mean=$(cat "${RKT_TMP_DIR}/racket/${name}${disk_aux_name}.runtime")

    # longest proxy chain figure
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,960"`
            `"   noenhanced color font 'Verdana,26' ;"`
            `"set output '${longest_proxy_chain_fig}';"`
            `"set key opaque bottom left box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
            `"set title \"${printname}\";"`
            `"set xlabel \"How much of the code is typed\";"`
            `"set ylabel \"Longest proxy chain\";"`
	    `"set yrange [0:*];"`
	    `"set ytics 0,1;"`
            `"plot '${config1_log_sorted}' using 2:8 with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
            `"'${config2_log_sorted}' using 2:8 with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}'"

    # runtime figure
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,960"`
            `"   enhanced color font 'Verdana,26' ;"`
            `"set output '${runtime_fig}';"`
            `"set key opaque top right box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
            `"set title \"${printname}\";"`
	    `"set xrange [0:100];"`
            `"set xlabel \"How much of the code is typed\";"`
            `"set ylabel \"Runtime in seconds\";"`
	    `"set yrange [0:*];"`
            `"plot '${config1_log_sorted}' using 2:3 with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
            `"'${config2_log_sorted}' using 2:3 with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}',"`
            `"${static_mean} lw 2 dt 2 lc \"blue\" title 'Static Grift',"`
            `"${dyn_mean} lw 2 dt 2 lc \"red\" title 'Dynamic Grift';"

    # runtime casts count figure
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,960"`
            `"   enhanced color font 'Verdana,26' ;"`
            `"set output '${casts_count_fig}';"`
            `"set key opaque bottom left box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
            `"set title \"${printname}\";"`
            `"set xlabel \"How much of the code is typed\";"`
            `"set ylabel \"Runtime casts count\";"`
            `"plot '${config1_log_sorted}' using 2:7 with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
            `"'${config2_log_sorted}' using 2:7 with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}'"

    # not showing longest proxy chains
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,1500"`
            `"   enhanced color font 'Verdana,26' ;"`
            `"set output '${runtime_and_casts_count_fig}';"`
            `"set lmargin at screen 0.15;"`
	    `"set rmargin at screen 0.95;"`
	    `"TOP=0.95;"`
	    `"DY = 0.45;"`
	    `"set multiplot;"`
            `"set xlabel \"How much of the code is typed\";"`
	    `"unset ylabel;"`
	    `"unset key;"`
	    `"set xrange [0:100];"`
	    `"set yrange [0:*];"` # set format y \"%.0t\";
            `"set label 2 \"Runtime casts count\" at screen 0.02,0.25 rotate by 90;"`
	    `"set tmargin at screen TOP-DY;"`
	    `"set bmargin at screen TOP+0.02-2*DY;"`
	    `"unset key;"`
            `"plot '${config1_log_sorted}' using 2:7 with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
            `"'${config2_log_sorted}' using 2:7 with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}';"`
	    `"set format x '';"`
	    `"unset xlabel;"`
            `"set key opaque top right box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
	    `"set tmargin at screen TOP;"`
	    `"set bmargin at screen TOP+0.02-DY;"`
            `"set title \"${printname}\";"`
            `"set label 3 \"Runtime in seconds\" at screen 0.02,0.7 rotate by 90;"`
            `"plot '${config1_log_sorted}' using 2:3 with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
            `"'${config2_log_sorted}' using 2:3 with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}',"`
            `"${static_mean} lw 2 dt 2 lc \"blue\" title 'Static Grift',"`
            `"${dyn_mean} lw 2 lt 1 lc \"red\" title 'Dynamic Grift';"

    # showing runtime and longest proxy chain all in one figure
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,1500"`
            `"   enhanced color font 'Verdana,26' ;"`
            `"set output '${runtime_and_longest_proxy_chain_fig}';"`
            `"set lmargin at screen 0.15;"`
	    `"set rmargin at screen 0.95;"`
	    `"TOP=0.95;"`
	    `"DY = 0.45;"`
	    `"set multiplot;"`
            `"set xlabel \"How much of the code is typed\";"`
	    `"unset ylabel;"`
            `"set label 1 \"Longest proxy chain\" at screen 0.02,0.25 rotate by 90;"`
	    `"set tmargin at screen TOP-DY;"`
	    `"set bmargin at screen TOP+0.02-2*DY;"`
	    `"unset key;"`
	    `"set yrange [0:*];"`
	    `"set ytics 0,1;"`
	    `"set xrange [0:100];"`
	    `"max(x,y) = (x > y) ? x : y;"`
            `"plot '${config1_log_sorted}' using 2:(max(\$19, (max(\$20, \$21)))) with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
	    `"'${config2_log_sorted}' using 2:(max(\$19, (max(\$20, \$21)))) with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}';"`
	    `"unset xtics;"`
	    `"set ytics auto;"`
	    `"unset xlabel;"`
	    `"set format x '';"`
	    `"set yrange [0:*];"`
            `"set key opaque top right box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
	    `"set tmargin at screen TOP;"`
	    `"set bmargin at screen TOP+0.02-DY;"`
            `"set title \"${printname}\";"`
            `"set label 3 \"Runtime in seconds\" at screen 0.02,0.75 rotate by 90;"`
            `"plot '${config1_log_sorted}' using 2:3 with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
            `"'${config2_log_sorted}' using 2:3 with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}',"`
            `"${static_mean} lw 2 dt 2 lc \"blue\" title 'Static Grift',"`
            `"${dyn_mean} lw 2 lt 1 lc \"red\" title 'Dynamic Grift';"

    
    # showing runtime, casts count, and longest proxy chain all in one figure
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,1900"`
            `"   enhanced color font 'Verdana,26' ;"`
            `"set output '${all_fig}';"`
            `"set lmargin at screen 0.15;"`
	    `"set rmargin at screen 0.95;"`
	    `"TOP=0.95;"`
	    `"DY = 0.29;"`
	    `"set multiplot;"`
            `"set xlabel \"How much of the code is typed\";"`
	    `"unset ylabel;"`
            `"set label 1 \"Longest proxy chain\" at screen 0.02,0.15 rotate by 90;"`
	    `"set tmargin at screen TOP-2*DY;"`
	    `"set bmargin at screen TOP-3*DY;"`
	    `"unset key;"`
	    `"set yrange [0:*];"`
	    `"set ytics 0,1;"`
	    `"set xrange [0:100];"`
	    `"max(x,y) = (x > y) ? x : y;"`
            `"plot '${config1_log_sorted}' using 2:(max(\$19, (max(\$20, \$21)))) with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
	    `"'${config2_log_sorted}' using 2:(max(\$19, (max(\$20, \$21)))) with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}';"`
	    `"unset xtics;"`
	    `"set ytics auto;"`
	    `"unset xlabel;"`
	    `"set format x '';"`
	    `"set yrange [0:*];"`
            `"set label 2 \"Runtime casts count\" at screen 0.02,0.45 rotate by 90;"`
	    `"set tmargin at screen TOP-DY;"`
	    `"set bmargin at screen TOP+0.02-2*DY;"`
	    `"unset key;"`
            `"plot '${config1_log_sorted}' using 2:7 with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
            `"'${config2_log_sorted}' using 2:7 with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}';"`
            `"set key opaque top right box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
	    `"set tmargin at screen TOP;"`
	    `"set bmargin at screen TOP+0.02-DY;"`
            `"set title \"${printname}\";"`
            `"set label 3 \"Runtime in seconds\" at screen 0.02,0.75 rotate by 90;"`
	    `"set ytics auto;"`
            `"plot '${config1_log_sorted}' using 2:3 with points"` 
            `"   pt 9 ps 3 lc rgb '$color1' title '${c1t}',"`
            `"'${config2_log_sorted}' using 2:3 with points"`
            `"   pt 6 ps 3 lc rgb '$color2' title '${c2t}',"`
            `"${static_mean} lw 2 dt 2 lc \"blue\" title 'Static Grift',"`
            `"${dyn_mean} lw 2 lt 1 lc \"red\" title 'Dynamic Grift';"

        # cumulative performance figures
        gnuplot -e "set datafile separator \",\"; set terminal pngcairo "`
                `"enhanced color font 'Verdana,20' size 1000,400;"`
                `"set output '${cumulative_performance_fig}';"`
                `"set border 15 back;"`
                `"unset key;"`
                `"set ylabel \"${printname}\";"`
                `"stats '${config2_log_sorted}' using 4 nooutput;"`
		`"type_based_max_slowdown = ceil(STATS_max);"`
                `"stats '${racket_log}' using 3 nooutput;"`
		`"racket_max_slowdown = ceil(STATS_max);"`
		`"added = STATS_records*5/100;"`
                `"set yrange [1:STATS_records+added];"`
	        `"max(x,y) = (x > y) ? x : y;"`
                `"set ytics (1, STATS_records/2, STATS_records);"`
		`"set logscale x;"`
                `"stats '${config1_log_sorted}' using 4 nooutput;"`
		`"coercion_max_slowdown = ceil(STATS_max);"`
		`"range_max = max(max(max(racket_max_slowdown, 20), type_based_max_slowdown), coercion_max_slowdown);"`
                `"set xrange [0:range_max];"`
                `"set arrow from coercion_max_slowdown,graph(0,0) to coercion_max_slowdown,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from type_based_max_slowdown,graph(0,0) to type_based_max_slowdown,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from racket_max_slowdown,graph(0,0) to racket_max_slowdown,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set xtics nomirror (1, 2, coercion_max_slowdown, type_based_max_slowdown, racket_max_slowdown, range_max);"`
		`"print \"type_based_max_slowdown=\",type_based_max_slowdown;"`
		`"print \"coercion_max_slowdown=\",coercion_max_slowdown;"`
		`"print \"racket_max_slowdown=\",racket_max_slowdown;"`
                `"set arrow from 1,graph(0,0) to 1,graph(1,1) nohead lc rgb \"black\" lw 2;"`
                `"set arrow from 2,graph(0,0) to 2,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from 3,graph(0,0) to 3,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from 4,graph(0,0) to 4,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from 5,graph(0,0) to 5,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from 6,graph(0,0) to 6,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from 7,graph(0,0) to 7,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from 8,graph(0,0) to 8,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from 9,graph(0,0) to 9,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"set arrow from 10,graph(0,0) to 10,graph(1,1) nohead dt \".\" lc rgb \"black\" lw 1;"`
                `"plot '${config1_log_sorted}' using (\$3/${racket_mean}):(1.) lc rgb '$color1' lw 3 title '${c1t}' smooth cumulative,"`
                `"     '${config2_log_sorted}' using (\$3/${racket_mean}):(1.) lc rgb '$color2' lw 3 title '${c2t}' smooth cumulative,"`
		`"     '${racket_log}' using 3:(1.) lc rgb '$color3' lw 3 title 'Typed Racket' smooth cumulative"
}
