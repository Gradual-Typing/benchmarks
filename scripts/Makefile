INPUT_TYPE ?=release
BIN_SAMPLES ?= -1
NUM_BINS ?= 30
TIMING_SAMPLES ?= 5
ROOT_DIR ?=/app/experiments
TEST_DIR=test
BENCHMARK_DIR ?=fresh
IDEAL_CONFIGS ?=17
CONFIGS ?=17 7
DYNAMIC_GRIFT_CONFIG ?=17
OVERWRITE ?= false

.PHONY: external fine coarse release plot clean test-clean outputs

release: coarse plot-coarse fine plot-fine external create-figs

create-figs:
	./paper_figs.sh $(ROOT_DIR) $(DYNAMIC_GRIFT_CONFIG) $(CONFIGS)

plot-coarse:
	./plot_partial.sh $(ROOT_DIR) coarse $(DYNAMIC_GRIFT_CONFIG) $(CONFIGS)

plot-fine:
	./plot_partial.sh $(ROOT_DIR) fine $(DYNAMIC_GRIFT_CONFIG) $(CONFIGS)

external:
	./grift_external.sh $(TIMING_SAMPLES) $(ROOT_DIR) $(BENCHMARK_DIR) $(OVERWRITE) \
		$(IDEAL_CONFIGS)

fine:
	./grift_partial.sh $(ROOT_DIR) $(TIMING_SAMPLES) $(BENCHMARK_DIR) true fine \
		$(NUM_BINS) $(BIN_SAMPLES) $(INPUT_TYPE) $(OVERWRITE) $(CONFIGS)

coarse:
	./racket_partial.sh $(ROOT_DIR) $(TIMING_SAMPLES) $(BENCHMARK_DIR) $(INPUT_TYPE) \
		$(OVERWRITE)
	./grift_partial.sh $(ROOT_DIR) $(TIMING_SAMPLES) $(BENCHMARK_DIR) true coarse \
		$(NUM_BINS) $(BIN_SAMPLES) $(INPUT_TYPE) $(OVERWRITE) $(CONFIGS)

test-coarse:
	INPUT_TYPE=test TIMING_SAMPLES=1 BIN_SAMPLES=1 NUM_BINS=2 \
	BENCHMARK_DIR=$(TEST_DIR) ROOT_DIR=".." \
		$(MAKE) coarse plot-coarse

test-fine:
	INPUT_TYPE=test TIMING_SAMPLES=1 BIN_SAMPLES=1 NUM_BINS=2 \
	BENCHMARK_DIR=$(TEST_DIR) ROOT_DIR=".." \
		$(MAKE) fine plot-fine

test-external:
	INPUT_TYPE=test TIMING_SAMPLES=1 BIN_SAMPLES=1 NUM_BINS=2 \
	BENCHMARK_DIR=$(TEST_DIR) ROOT_DIR=".." \
		$(MAKE) external

test: test-coarse test-fine test-external create-figs

test-overwrite:
	OVERWRITE=true \
		$(MAKE) test-coarse test-fine test-external create-figs

release-fast:
	INPUT_TYPE=test TIMING_SAMPLES=1 $(MAKE) release

clean:
	find external results -executable -and \( -not -type d \) -delete
	find external results -type d -and -name "compiled" -exec rm -r {} \;
	$(MAKE) -C src clean

test-clean:
	rm -rf $(ROOT_DIR)/results/grift/external/$(TEST_DIR)
	rm -rf $(ROOT_DIR)/results/grift/partial/fine/$(TEST_DIR)
	rm -rf $(ROOT_DIR)/results/grift/partial/coarse/$(TEST_DIR)
	rm -rf $(ROOT_DIR)/results/typed_racket/partial/coarse/$(TEST_DIR)

outputs:
	$(MAKE) -C outputs
