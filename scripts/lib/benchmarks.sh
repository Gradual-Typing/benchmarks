#!/bin/sh

declare -a BENCHMARKS=(quicksort fft blackscholes matmult n_body tak ray array)

declare -a BENCHMARKS_ARGS_LATTICE=("in_descend1000.txt" "slow.txt" "in_4K.txt" "400.txt" "slow.txt" "slow.txt" "empty.txt" "slow.txt")
