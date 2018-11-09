BIN_SAMPLES ?= 30
NUM_BINS ?= 30
TIMING_SAMPLES ?= 10
ROOT_DIR ?=/app/experiments
TEST_DIR=test
BENCHMARK_DIR ?=fresh

.PHONY: external fine coarse all clean test-clean outputs

all: external coarse fine

external:
	./extremes.sh $(TIMING_SAMPLES) $(ROOT_DIR) $(BENCHMARK_DIR) 17 19

fine:
	./lattice_bins.sh $(ROOT_DIR) $(TIMING_SAMPLES) $(BENCHMARK_DIR) true fine \
		$(BIN_SAMPLES) $(NUM_BINS) 17 7 19 17 17 13 19 15 17 8 19 11

coarse:
	./lattice_bins.sh $(ROOT_DIR) $(TIMING_SAMPLES) $(BENCHMARK_DIR) true coarse \
		$(BIN_SAMPLES) $(NUM_BINS) 17 7 19 17 17 13 19 15 17 8 19 11

test:
	TIMING_SAMPLES=1 BIN_SAMPLES=1 NUM_BINS=10 BENCHMARK_DIR=$(TEST_DIR) ROOT_DIR=".." \
		$(MAKE) all

clean:
	find extremes lattice_bins -executable -and \( -not -type d \) -delete
	find extremes lattice_bins -type d -and -name "compiled" -exec rm -r {} \;
	$(MAKE) -C src clean

test-clean:
	rm -rf $(ROOT_DIR)/extremes/$(TEST_DIR) $(ROOT_DIR)/lattice_bins/$(TEST_DIR)

outputs:
	$(MAKE) -C outputs
