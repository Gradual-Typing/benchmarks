.PHONY: all clean outs

targets=array fft n_body ray blackscholes matmult quicksort tak sieve

all: $(targets)

clean:
	find . -not \( -name "*.scm" -or -name "Makefile" \) -delete

%: %.scm
	gsc -exe -o $@ -cc-options "-O3" $@.scm
