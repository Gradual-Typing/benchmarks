#!/bin/sh

# needed so that anyone can access the files
umask 000

# runtime.sh and benchmarks.sh should be sourced before calling any of these functions

function plot_one_config_fine()
{
    local config="$1";     shift
    local dyn_config="$1"; shift

    color="$DGREEN"

    local config_str=$(grift-configs -n $config)

    for benchmark in "${BENCHMARKS[@]}"; do
	plot_one_config_fine_benchmark "$benchmark" $config "$config_str" $dyn_config
    done
}

function plot_one_config_fine_benchmark()
{
    local name="$1";       shift
    local config="$1";     shift
    local config_str="$1"; shift
    local dyn_config="$1"; shift

    local plot_dir="${OUT_DIR}/${config_str}"
    local runtimes_dir="${plot_dir}/runtimes"
    local casts_dir="${plot_dir}/casts"
    local mono_dir="${plot_dir}/mono"
    local longest_proxy_chains_dir="${plot_dir}/longest_proxy_chains"
    local all_dir="${plot_dir}/all"
    local cumulative_performance_dir="${plot_dir}/cum_perf"

    mkdir -p "$runtimes_dir"
    mkdir -p "$casts_dir"
    mkdir -p "$mono_dir"
    mkdir -p "$longest_proxy_chains_dir"
    mkdir -p "$all_dir"
    mkdir -p "$cumulative_performance_dir"

    local runtime_fig="${runtimes_dir}/${name}.png"
    local casts_count_fig="${casts_dir}/${name}.png"
    local mono_fig="${mono_dir}/${name}.png"
    local longest_proxy_chain_fig="${longest_proxy_chains_dir}/${name}.png"
    local all_fig="${all_dir}/${name}.png"
    local cumulative_performance_fig="${cumulative_performance_dir}/${name}.png"

    local config_log="${DATA_DIR}/${name}${config}.log"
    local config_log_sorted="${DATA_DIR}/${name}${config}.log.sorted"
    local config_cumulative_log="${DATA_DIR}/${name}${config}.csv"

    if [ ! -f "$config_log" ]; then
	echo "Warning: log file at path: ${config_log} is not found"
	return
    fi

    # sort log files according to the second column that contains the precentage
    # of typed code and disregard the header row
    tail -n +2 "$config_log" | sort -k2 -n -t, > "${config_log_sorted}"

    # deletes the first line which contains the fully untyped configuration
    sed -i "1d" "${config_log_sorted}"

    print_aux_name=""
    printname="$(echo "$name" | tr _ "-")${print_aux_name}"

    # They are currently unused
    speedup_geometric_mean "$config_log_sorted"
    config_speedup_geometric_mean="$RETURN"
    runtime_mean "$config_log_sorted"
    config_runtime_mean="$RETURN"

    dyn_mean=$(cat "${TMP_DIR}/dyn/${name}${disk_aux_name}${dyn_config}.runtime")
    static_mean=$(cat "${TMP_DIR}/static/${name}/single/${name}${disk_aux_name}.static.runtime")

    if [ ! -f "$config_cumulative_log" ]; then
	# create data files for the cummulative performance figures
	tail -n +2 "$config_log_sorted" |\
	    awk -F "," -v x="$dyn_mean" '{printf "%4.2f\n", $3/x }' | \
            sort | \
            uniq -c | \
            awk ' { t = $1; $1 = $2; $2 = t; print; } ' | \
            awk '{ $1=$1" ,";; print }' > "$config_cumulative_log"
    fi

    # longest proxy chain figure
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,960"`
            `"   noenhanced color font 'Verdana,26' ;"`
            `"set output '${longest_proxy_chain_fig}';"`
            `"set key opaque bottom left box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
            `"set title \"${printname}\";"`
            `"set xlabel \"How much of the code is typed\";"`
            `"set ylabel \"Longest proxy chain\";"`
            `"plot '${config_log_sorted}' using 2:8 with points"` 
            `"   pt 9 ps 3 lc rgb '$color' title 'Grift'"

    # runtime figure
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,960"`
            `"   enhanced color font 'Verdana,26' ;"`
            `"set output '${runtime_fig}';"`
            `"set key opaque top right box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
            `"set title \"${printname}\";"`
   	    `"stats '${config_log_sorted}' nooutput;"`
	    `"set xrange [0:STATS_records+10];"`
	    `"divby=STATS_records/4;"`
	    `"set xtics ('0%%' 0, '25%%' divby, '50%%' divby*2, '75%%' divby*3, '100%%' divby*4) nomirror;"`
            `"set xlabel \"How much of the code is typed\";"`
            `"set ylabel \"Runtime in seconds\";"`
	    `"set palette maxcolors 2;"`
	    `"set palette model RGB defined ( 0 '$color', 1 '$color' );"` # 0 should be red
	    `"unset colorbox;"`
            `"plot '${config_log_sorted}' using 0:( strcol(1) eq \"dyn\" ? NaN : \$3 ) with points"` 
            `"   pt 9 ps 3 lc rgb '$color' title 'Grift',"`
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
            `"plot '${config_log_sorted}' using 2:7 with points"` 
            `"   pt 9 ps 3 lc rgb '$color' title '${c1t}'"

    # not showing longest proxy chains for monotonic
    gnuplot -e "set datafile separator \",\";"`
            `"set terminal pngcairo size 1280,1500"`
            `"   enhanced color font 'Verdana,26' ;"`
            `"set output '${mono_fig}';"`
            `"set lmargin at screen 0.15;"`
	    `"set rmargin at screen 0.95;"`
	    `"TOP=0.95;"`
	    `"DY = 0.45;"`
	    `"set multiplot;"`
            `"set xlabel \"How much of the code is typed\";"`
	    `"unset ylabel;"`
	    `"unset key;"`
	    `"stats '${config_log_sorted}' nooutput;"`
	    `"set xrange [0:STATS_records+10];"`
	    `"divby=STATS_records/4;"`
	    `"set xtics ('0%%' 0, '25%%' divby, '50%%' divby*2, '75%%' divby*3, '100%%' divby*4) nomirror;"`
	    `"max(x,y) = (x > y) ? x : y;"`
	    `"set format x '';"`
	    `"set yrange [0:*];"`
            `"set label 2 \"Runtime casts count\" at screen 0.02,0.25 rotate by 90;"`
	    `"set tmargin at screen TOP-DY;"`
	    `"set bmargin at screen TOP+0.02-2*DY;"`
	    `"unset key;"`
            `"plot '${config_log_sorted}' using 0:7 with points"` 
            `"   pt 9 ps 3 lc rgb '$color' title 'Grift';"`
	    `"unset xtics; unset xlabel;"`
            `"set key opaque top right box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
	    `"set tmargin at screen TOP;"`
	    `"set bmargin at screen TOP+0.02-DY;"`
            `"set title \"${printname}\";"`
            `"set label 3 \"Runtime in seconds\" at screen 0.02,0.7 rotate by 90;"`
	    `"set palette maxcolors 2;"`
	    `"set palette model RGB defined ( 0 '$color', 1 '$color' );"`
	    `"unset colorbox;"`
            `"plot '${config_log_sorted}' using 0:( strcol(1) eq \"dyn\" ? NaN : \$3 ) with points"` 
            `"   pt 9 ps 3 lc rgb '$color' title 'Grift',"`
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
	    `"stats '${config_log_sorted}' using 19 nooutput;"`
	    `"set ytics 1;"`
	    `"set xrange [0:STATS_records+10];"`
	    `"divby=STATS_records/4;"`
	    `"set xtics ('0%%' 0, '25%%' divby, '50%%' divby*2, '75%%' divby*3, '100%%' divby*4) nomirror;"`
	    `"max(x,y) = (x > y) ? x : y;"`
	    `"set yrange [0:*];"`
            `"plot '${config_log_sorted}' using 0:(max(\$19, (max(\$20, \$21)))) with points"` 
            `"   pt 9 ps 3 lc rgb '$color' title 'Grift';"`
	    `"unset xtics;"`
	    `"unset xlabel;"`
	    `"set format x '';"`
	    `"set yrange [0:*];"`
	    `"set ytics auto;"`
            `"set label 2 \"Runtime casts count\" at screen 0.02,0.45 rotate by 90;"`
	    `"set tmargin at screen TOP-DY;"`
	    `"set bmargin at screen TOP+0.02-2*DY;"`
	    `"unset key;"`
            `"plot '${config_log_sorted}' using 0:7 with points"` 
            `"   pt 9 ps 3 lc rgb '$color' title 'Grift';"`
            `"set key opaque top right box vertical width 1 height 1 maxcols 1 spacing 1 font 'Verdana,20';"`
	    `"set tmargin at screen TOP;"`
	    `"set bmargin at screen TOP+0.02-DY;"`
            `"set title \"${printname}\";"`
            `"set label 3 \"Runtime in seconds\" at screen 0.02,0.75 rotate by 90;"`
	    `"set palette maxcolors 2;"`
	    `"set palette model RGB defined ( 0 '$color', 1 '$color' );"`
	    `"unset colorbox;"`
            `"plot '${config_log_sorted}' using 0:( strcol(1) eq \"dyn\" ? NaN : \$3 ) with points"` 
            `"   pt 9 ps 3 lc rgb '$color' title 'Grift',"`
            `"${static_mean} lw 2 dt 2 lc \"blue\" title 'Static Grift',"`
            `"${dyn_mean} lw 2 lt 1 lc \"red\" title 'Dynamic Grift';"

        # cumulative performance figures
        gnuplot -e "set datafile separator \",\"; set terminal pngcairo "`
                `"enhanced color font 'Verdana,10' ;"`
                `"set output '${cumulative_performance_fig}';"`
                `"set border 15 back;"`
                `"set title \"${printname}\";"`
                `"stats '${config_log_sorted}' nooutput;"`
                `"set yrange [0:STATS_records];"`
                `"set xrange [0:10];"`
                `"set xtics nomirror (\"1x\" 1,\"2x\" 2,\"3x\" 3,\"4x\" 4,\"5x\" 5, \"6x\" 6,\"7x\" 7, \"8x\" 8, \"9x\" 9, \"10x\" 10, \"15x\" 15, \"20x\" 20);"`
                `"set ytics nomirror 0,200;"`
                `"set arrow from 1,graph(0,0) to 1,graph(1,1) nohead lc rgb \"black\" lw 2;"`
                `"plot '${config_cumulative_log}' using 1:2 with lines lw 2 dt 4 title 'Grift' smooth cumulative"
}
