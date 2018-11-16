#! racket
#lang racket

(define (rand size)
  (for/vector #:length size ([_ (in-range size)])
    (cons (random size) (random size))))

(define (descend size)
  (for/vector #:length size ([i (in-range size 0 -1)])
    (cons i (+ i 1))))

(define (print-vector v)
  (printf "~a\n" (vector-length v))
  (for ([p (in-vector v)])
    (printf "~a ~a\n" (car p) (cdr p))))

(module+ main
  (define main-fn (make-parameter rand))
  (command-line
   #:once-any
   [("--descend")"Generate descending pairs" (main-fn descend)]
   [("--rand") "Generate random pairs" (main-fn rand)]
   #:args (size)
   (define n? (string->number size))
   (unless (and (exact-nonnegative-integer? n?) (< 0 n?))
     (error 'qsort-mpairs.rkt "expected possitive integer: ~a" size))
   (print-vector ((main-fn) n?))))
