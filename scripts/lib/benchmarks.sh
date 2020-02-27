#!/bin/sh

declare -a BENCHMARKS=(sieve fft blackscholes n_body ray quicksort matmult tak array)

declare -a BENCHMARKS_ARGS_PARTIAL_COARSE=("fast.txt" "medium1.txt" "in_4K.txt" "slow.txt" "fast.txt" "in_descend1000.txt" "400.txt" "slow.txt" "slow.txt")

declare -a BENCHMARKS_ARGS_PARTIAL_FINE=("trivial.txt" "medium1.txt" "in_4K.txt" "slow.txt" "fast.txt" "in_descend1000.txt" "400.txt" "slow.txt" "slow.txt")

declare -a BENCHMARKS_ARGS_TRIVIAL=("trivial.txt" "fast.txt" "in_4K.txt" "fast.txt" "fast.txt" "in_descend1000.txt" "200.txt" "slow.txt" "slow.txt")

declare -a BENCHMARKS_ARGS_EXTERNAL=("slow.txt" "slow2.txt" "in_16K.txt" "slow.txt" "slow.txt" "in_descend10000.txt" "400.txt" "slow.txt" "slow.txt")
