#lang racket/base

;; Use the partner file "streams.rkt" to implement the Sieve of Eratosthenes.
;; Then compute and print the 10,000th prime number.

(require "streams.rkt")

;;--------------------------------------------------------------------------------------------------

;; `count-from n` Build a stream of integers starting from `n` and iteratively adding 1

(define (count-from n)
  (make-stream n (lambda () (count-from (add1 n)))))

;; `sift n st` Filter all elements in `st` that are equal to `n`.
;; Return a new stream.
(define (sift n st)
  (define hd (stream-first st))
  (cond
    [(eq? 0 (modulo hd n))
     (sift n (stream-rest st))]
    [else
     (make-stream hd (lambda () (sift n (stream-rest st))))]))

;; `sieve st` Sieve of Eratosthenes
(define (sieve st)
  (define hd (stream-first st))
  (make-stream hd (lambda () (sieve (sift hd (stream-rest st))))))

;; stream of prime numbers
(define primes (sieve (count-from 2)))

(define (main)
  (let ([N-1 (read)])
    (display (stream-get primes N-1))
    (newline)))

(time (main))
