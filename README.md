Collection of benchmarks for gradually typed languages.

## Quick Start Guide

To get started

0. install [docker](https://docs.docker.com/install/).

1. clone

		$ git clone https://github.com/Gradual-Typing/benchmarks.git
		$ cd benchmarks
		$ git checkout pldi19

2. run the full benchmark suite:

		$ docker pull dalmahal90/grift-benchmarks:pldi19
		$ make release

## Getting Started

- `make build`: builds the Docker image.

- `make attach`: run and attach to the container in an interactive mode.

- `make test-coarse`: testing coarse-grained gradual typing: for all benchmarks,
  generates, compiles, and runs all partially typed configurations where each
  module is either typed or untyped. This is done for Grift with type-based casts,
  Grift with coercions, and Typed Racket. It should take around 25 minutes to
  finish. The purpose of this command is to make sure the scripts work and there
  are no errors, so no output files to be expected.

- `make test-fine`: testing fine-grained gradual typing: for all benchmarks, two
  partially-typed configurations are sampled where any type annotation can be Dyn,
  compiled and ran by Grift with type-based casts and Grift with coercions. It
  should take around 10 minutes to finish. Again, this is done on small input
  sizes to make sure everything works as intended. There is no output.

- `make test-external`: testing Grift with coercions against other
  statically-typed and dynamically-typed languages. It should take around 5
  minutes to finish. There is no output.
  
- `make test`: runs all three recipes `test-coarse`, `test-fine`, and
  `test-external`. In addition, it creates Figures 7, 8, and 9 from the paper
  using the data in collected from these runs. The expected disk space used is
  around 550MB and the total runtime will be around 40 minutes.

- `make release-fast`: runs `test-coarse` and `test-external`. However, for the
  fine-grained experiments, instead of just 2, a linear number of configurations
  will be sampled. This will take significantly longer to finish, perhaps less
  than 10 hours.

- `make release`: is similar to the `release-fast` recipe but with each
  configuration run 5 times instead of 1. This experiment is expected to take a
  few days to finish and needs 10-20GB.

- `make rm-container`: deletes the container.

- `make setup-dir`: copies files from the current directory to the benchmarking
  directory accessed by the docker container.
