Collection of benchmarks for gradually typed languages

## Getting Started

<description of how to use the VM>

This artifact implements the performance evaluation methodology presented in
"Toward Efficient Gradual Typing for Structural Types via Coercions". In
particular, the output of this work is Figures 6,7, and 8 in the paper. The
artifact consists of a virtual machine that is pre-loaded with all the necessary
software to run the experiments. Running the same experiment presented in the
paper might take around a week to finish on a single powerful machine. However,
we also provide different options that will take significantly less time to
finish. The following is a list of simple `make` commands with descriptions of
what they do and what to expect as output:

- `make test_coarse`: testing coarse-grained gradual typing: for all benchmarks,
generates, compiles, and runs all partially typed configurations where each
module is either typed or untyped. This is done for Grift with type-based casts,
Grift with coercions, and Typed Racket. It should take around 25 minutes to
finish, thanks to the input sizes being much smaller than the ones used in the
paper. The purpose of this command is to make sure the scripts work and there
are no errors, so no output files to be expected.

- `make test_fine`: testing fine-grained gradual typing: for all benchmarks, two
partially-typed configurations are sampled where any type annotation can be Dyn,
compiled and ran by Grift with type-based casts and Grift with coercions. It
should take around 10 minutes to finish. Again, this is done on small input
sizes to make sure everything works as intended. There is no output.

- `make test_external`: testing Grift with coercions against other
  statically-typed and dynamically-typed languages. It should take around 5
  minutes to finish. There is no output.
  
- `make test`: runs all three recipes `test_coarse`, `test_fine`, and
  `test_external` together. In addition, it creates Figures 6, 7, and 8 from the
  paper using the data in collected from these runs. The expected disk space
  used is around 550MB and the total runtime will be around 40 minutes.

- `make release-fast`: runs `test_coarse` and `test_external`. However, for the
  fine-grained experiments, 900 configurations instead of 2 will be
  sampled. This will takes significantly longer to finish, perhaps less than 10 hours.

- `make release`: is similar to the `release-fast` recipe but with the same
  input sizes as the ones used for the data in the paper and each configuration
  is run 10 times instead of 1. This experiment is expected to take a week to
  finish and needs 10-20GB.
