#lang racket

;;; Here we actively choose to not use racket racket/fixnum. Use of
;;; generic numeric ops is disadvantage for racket but there is no
;;; safe version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)

(require "helpers.rkt")

(define (sort a p r)
  (if (< p r)
      (let ([q (partition a p r)])
	(begin
	  (sort a p (- q 1))
	  (sort a (+ q 1) r)))
      0))

(define (main)
  (let ([size (read)])
    (let ([a (make-vector size 1)])
      (begin
        (let loop ([i 0])
          (if (< i size)
              (begin
                (vector-set! a i (read))
                (loop (+ i 1)))
              0))
        (sort a 0 (- size 1))
        (display (vector-ref a (- size 1)))))))

(time (main))
