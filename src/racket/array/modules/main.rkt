#lang racket/base

(require racket/pretty)

(require "helpers.rkt")

;;; ARRAY1 -- One of the Kernighan and Van Wyk benchmarks.

;;; Here we actively choose to not use racket racket/fixnum. Use of
;;; generic numeric ops is disadvantage for racket but there is no
;;; safe version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)

(define (my-try n)
  (vector-length (create-y (create-x n))))

(define (go m n r)
  (if (> m 0)
      (go (- m 1) n (my-try n))
      r))

(define (main)
  (let* ((input1 (read))
         (input2 (read)))
    (pretty-print (go input1 input2 0))))

(time (main))
