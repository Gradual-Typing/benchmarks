IMAGE_NAME=benchmarks
CONTAINER_NAME=benchmarks_container
HOST_EXPERIMENT_DIR=/home/$(USER)/experiments
CONTAINER_EXPERIMENT_DIR=/app/experiments
DOCKER_BUILD_FLAGS=--build-arg CACHE_DATE=$(date +%Y-%m-%d:%H:%M:%S) --build-arg EXPR_DIR=$(CONTAINER_EXPERIMENT_DIR)

all: build run

.PHONY: all build run docker-clean

build:
	time docker build $(DOCKER_BUILD_FLAGS) -t $(IMAGE_NAME) . 2>&1 | tee $<.log

# --userns=host is needed because of https://docs.docker.com/engine/security/userns-remap/
# beware that the files created on the host volume will be owned by root
run:
	cp -r ./* $(HOST_EXPERIMENT_DIR)
	docker run --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME)

debug:
	time docker build $(DOCKER_BUILD_FLAGS) -t $(IMAGE_NAME) . 2>&1 | tee $<.log
	rm -rf $(HOST_EXPERIMENT_DIR)/*
	cp -r ./* $(HOST_EXPERIMENT_DIR)
	docker run --rm -it --userns=host \
		-v $(HOST_EXPERIMENT_DIR):$(CONTAINER_EXPERIMENT_DIR) \
		--name=$(CONTAINER_NAME) $(IMAGE_NAME) /bin/bash

docker-clean:
	@echo "Remove all non running containers"
	-docker rm `docker ps -q -f status=exited`
	@echo "Delete all untagged/dangling (<none>) images"
	-docker rmi `docker images -q -f dangling=true`
