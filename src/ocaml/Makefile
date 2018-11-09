.PHONY: clean all

targets=array fft n_body ray blackscholes matmult quicksort tak sieve

all: $(targets)

clean:
	find . -not \( -name "*.ml" -or -name "Makefile" \) -delete

%: time.ml ocaml_%.ml
	ocamlopt -O3 -o $@ unix.cmxa time.ml ocaml_$@.ml



