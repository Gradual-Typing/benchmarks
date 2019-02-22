IMAGE_NAME=benchmarks
CONTAINER_NAME=benchmarks_container
HOST_EXPERIMENT_DIR=/home/$(USER)/experiments
CONTAINER_EXPERIMENT_DIR=/app/experiments
DATE=$(shell date +%Y-%m-%d:%H:%M:%S)
DOCKER_BUILD_FLAGS=--build-arg CACHE_DATE=$(DATE) --build-arg EXPR_DIR=$(CONTAINER_EXPERIMENT_DIR)
DOCKER_BUILD_FLAGS_UNSET_CACHE_DATE= --build-arg EXPR_DIR=$(CONTAINER_EXPERIMENT_DIR)

all: build run

.PHONY: all build build-no-cache run docker-clean attach setup_dir

build:
	time docker build $(DOCKER_BUILD_FLAGS) -t $(IMAGE_NAME) . 2>&1 | tee $<.log

build-no-cache:
	time docker build --no-cache $(DOCKER_BUILD_FLAGS) -t $(IMAGE_NAME) . 2>&1 | tee $<.log

build-unset-arg:
	time docker build $(DOCKER_BUILD_FLAGS_UNSET_CACHE_DATE) -t $(IMAGE_NAME) . 2>&1 | tee $<.log

# --userns=host is needed because of https://docs.docker.com/engine/security/userns-remap/
# beware that the files created on the host volume will be owned by root
# --ulimit stack=-1 = ulimit -s unlimited; this is needed for fft
run:
	cp -r ./* $(HOST_EXPERIMENT_DIR)
	docker run --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--ulimit stack=-1 \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME)

run-test:
	cp -r ./* $(HOST_EXPERIMENT_DIR)
	docker run --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--ulimit stack=-1 \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME) time make test

run-test-coarse:
	cp -r ./* $(HOST_EXPERIMENT_DIR)
	docker run --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--ulimit stack=-1 \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME) time make test_coarse

run-test-fine:
	cp -r ./* $(HOST_EXPERIMENT_DIR)
	docker run --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--ulimit stack=-1 \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME) time make test_fine

run-test-external:
	cp -r ./* $(HOST_EXPERIMENT_DIR)
	docker run --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--ulimit stack=-1 \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME) time make test_external

run-release-fast:
	cp -r ./* $(HOST_EXPERIMENT_DIR)
	docker run --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--ulimit stack=-1 \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME) time make release-fast

run-release:
	cp -r ./* $(HOST_EXPERIMENT_DIR)
	docker run --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--ulimit stack=-1 \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME) time make release

setup_dir:
	@ mkdir -p $(HOST_EXPERIMENT_DIR)
	cp -r ./* $(HOST_EXPERIMENT_DIR)

typed_racket_benchmarks/.git:
	git submodule update --init typed_racket_benchmarks

attach:
	docker run --rm -it --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--ulimit stack=-1 \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME) /bin/bash

debug: build typed_racket_benchmarks/.git setup_dir attach

debug_bench: build-unset-arg typed_racket_benchmarks/.git setup_dir attach

debug_nocache: build-no-cache typed_racket_benchmarks/.git setup_dir attach

test: typed_racket_benchmarks/.git setup_dir run-test

test-coarse: typed_racket_benchmarks/.git setup_dir run-test-coarse

test-fine: typed_racket_benchmarks/.git setup_dir run-test-fine

test-external: typed_racket_benchmarks/.git setup_dir run-test-external

release-fast: typed_racket_benchmarks/.git setup_dir run-release-fast

release: typed_racket_benchmarks/.git setup_dir run-release

docker-clean:
	@echo "Remove all non running containers"
	-docker rm `docker ps -q -f status=exited`
	@echo "Delete all untagged/dangling (<none>) images"
	-docker rmi `docker images -q -f dangling=true`

