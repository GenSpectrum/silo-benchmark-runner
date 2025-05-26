
# Required env vars:

# Should it be benchmarked at all? 0 for comparing the bechmark overhead
ifeq ($(BENCH),0)
EVOBENCH_LOG=
else ifeq ($(BENCH),1)
EVOBENCH_LOG=$(BENCH_DIR)/bench.log
else
$(error "BENCH must be either 0 or 1, got '$(BENCH)'")
endif
export EVOBENCH_LOG

# Should sorted input be used?
ifeq ($(SORTED),0)
INPUT_FILE = input_file.ndjson.zst
OUTPUT_DIR = output
else ifeq ($(SORTED),1)
INPUT_FILE = sorted_input_file.ndjson.zst
OUTPUT_DIR = sorted_output
else
$(error "SORTED must be either 0 or 1, got '$(SORTED)'")
endif
export OUTPUT_DIR

# Should API query order be randomized?
ifeq ($(RANDOMIZED),0)
API_QUERY_OPTS=
else ifeq ($(RANDOMIZED),1)
API_QUERY_OPTS=--randomize
else
$(error "RANDOMIZED must be either 0 or 1, got '$(RANDOMIZED)'")
endif


RESULT_BASENAME := bench=$(BENCH)_sorted=$(SORTED)_randomized=$(RANDOMIZED)_$(shell date --rfc-3339=seconds)
export RESULT_BASENAME

all: bench

# ---- Get dependencies --------------------------------------------------------

API_QUERY_VERSION=f1d7ff35b03ac740a58186578bf38e8cc39acc67

API_QUERY_DIR=api-query
API_QUERY_CLONE=$(API_QUERY_DIR)/Cargo.toml
API_QUERY_CHECKOUT_STAMP_DIR=$(API_QUERY_DIR)/.git/.checkout
API_QUERY_CHECKOUT=$(API_QUERY_CHECKOUT_STAMP_DIR)/$(API_QUERY_VERSION)
API_QUERY=$(API_QUERY_DIR)/target/release/api-query

$(API_QUERY_CLONE):
	git clone https://github.com/GenSpectrum/api-query $(API_QUERY_DIR)

$(API_QUERY_CHECKOUT): $(API_QUERY_CLONE)
	rm -rf $(API_QUERY_CHECKOUT_STAMP_DIR) # remove previous version stamp
	( cd $(API_QUERY_DIR) && git remote update && git checkout -b local_hidden_$(API_QUERY_VERSION) $(API_QUERY_VERSION) )
	mkdir -p $(API_QUERY_CHECKOUT_STAMP_DIR)
	touch $(API_QUERY_CHECKOUT)

$(API_QUERY): $(API_QUERY_CHECKOUT)
	cd $(API_QUERY_DIR) && cargo build --release


EVOBENCH_VERSION=bbe058547a3105c8cace9f4fe44ffc0dd0ceb26f

EVOBENCH_DIR=evobench
EVOBENCH_CLONE=$(EVOBENCH_DIR)/evobench-evaluator/Cargo.toml
EVOBENCH_CHECKOUT_STAMP_DIR=$(EVOBENCH_DIR)/.git/.checkout
EVOBENCH_CHECKOUT=$(EVOBENCH_CHECKOUT_STAMP_DIR)/$(EVOBENCH_VERSION)
EVOBENCH_EVALUATOR_DIR=$(EVOBENCH_DIR)/evobench-evaluator
EVOBENCH_EVALUATOR=$(EVOBENCH_EVALUATOR_DIR)/target/release/evobench-evaluator
export EVOBENCH_EVALUATOR

$(EVOBENCH_CLONE):
	git clone https://github.com/GenSpectrum/evobench/ $(EVOBENCH_DIR)

$(EVOBENCH_CHECKOUT): $(EVOBENCH_CLONE)
	rm -rf $(EVOBENCH_CHECKOUT_STAMP_DIR) # remove previous version stamp
	( cd $(EVOBENCH_DIR) && git remote update && git checkout -b local_hidden_$(EVOBENCH_VERSION) $(EVOBENCH_VERSION) )
	mkdir -p $(EVOBENCH_CHECKOUT_STAMP_DIR)
	touch $(EVOBENCH_CHECKOUT)

$(EVOBENCH_EVALUATOR): $(EVOBENCH_CHECKOUT)
	cd $(EVOBENCH_EVALUATOR_DIR) && cargo build --release


WISEPULSE_DIR=WisePulse
WISEPULSE_CHECKOUT=$(WISEPULSE_DIR)/Cargo.toml
WISEPULSE_BIN=$(WISEPULSE_DIR)/target/release
# Build the other binaries at the same time, too
WISEPULSE=$(WISEPULSE_BIN)/split_into_sorted_chunks

$(WISEPULSE_CHECKOUT):
	git clone https://github.com/cbg-ethz/WisePulse $(WISEPULSE_DIR)
	cd $(WISEPULSE_DIR) && git checkout -b sort-by-metadata-hack origin/sort-by-metadata-hack

$(WISEPULSE): $(WISEPULSE_CHECKOUT)
	cd $(WISEPULSE_DIR) && cargo build --release


# just for manual call comfort
dependencies: $(API_QUERY) $(EVOBENCH_EVALUATOR) $(WISEPULSE)


# ---- Sorting input -----------------------------------------------------------

sorted_input_file.ndjson.zst: input_file.ndjson.zst $(WISEPULSE)
	rm -rf sorted_chunks merger_tmp 
	zstdcat input_file.ndjson.zst \
	    | $(WISEPULSE_BIN)/split_into_sorted_chunks --output-path sorted_chunks --chunk-size 100000 --sort-field date \
	    | $(WISEPULSE_BIN)/merge_sorted_chunks --tmp-directory merger_tmp --sort-field date \
	    | zstd > sorted_input_file.ndjson.zst.tmp
	mv sorted_input_file.ndjson.zst.tmp sorted_input_file.ndjson.zst

# ---- Running silo -----------------------------------------------------------

SILO=../build/Release/silo
export SILO
API_OPTIONS=--api-threads-for-http-connections 16
export API_OPTIONS
PREPROCESSING_STAMP = $(OUTPUT_DIR)/.done

BENCH_DIR=/dev/shm/$(USER)/

$(BENCH_DIR)/.create:
	mkdir -p $(BENCH_DIR)
	touch $(BENCH_DIR)/.create

$(SILO):
	cd .. && python3 build_with_conan.py --release

$(PREPROCESSING_STAMP): $(SILO) $(INPUT_FILE)
	$(SILO) preprocessing --preprocessing-config preprocessing_config.yaml \
			--ndjson-input-filename $(INPUT_FILE) --output-directory $(OUTPUT_DIR)
	touch $(PREPROCESSING_STAMP)

.silo.pid: $(PREPROCESSING_STAMP) $(BENCH_DIR)/.create
	rm -f .silo.stopped
	bin/start-silo

.silo.stopped:
	bin/stop-silo
	touch .silo.stopped

bench: silo_queries.ndjson $(API_QUERY) $(EVOBENCH_EVALUATOR) .silo.stopped
	rm -f $(EVOBENCH_LOG)
	make .silo.pid
	$(API_QUERY) iter $(API_QUERY_OPTS) silo_queries.ndjson --drop --concurrency 50
	make .silo.stopped
	if [ $(BENCH) = 1 ]; then bin/process-log; fi

clean:
	rm -rf output sorted_output logs sorted_chunks merger_tmp sorted_input_file.ndjson.zst

clean-fully: clean
	rm -rf ../build

# ----------------------------------------------------------------------------

.PHONY:
	bench clean clean-fully
