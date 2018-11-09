#lang typed/racket/base

;; Use the partner file "streams.rkt" to implement the Sieve of Eratosthenes.
;; Then compute and print the 10,000th prime number.

(require "streams.rkt")

;;--------------------------------------------------------------------------------------------------

;; `count-from n` Build a stream of integers starting from `n` and iteratively adding 1
(: count-from (-> Natural stream))
(define (count-from n)
  (make-stream n (lambda () (count-from (add1 n)))))

;; `sift n st` Filter all elements in `st` that are equal to `n`.
;; Return a new stream.
(: sift (-> Natural stream stream))
(define (sift n st)
  (define hd (stream-first st))
  (cond
    [(= 0 (modulo hd n))
     (sift n (stream-rest st))]
    [else
     (make-stream hd (lambda () (sift n (stream-rest st))))]))

;; `sieve st` Sieve of Eratosthenes
(: sieve (-> stream stream))
(define (sieve st)
  (define hd (stream-first st))
  (make-stream hd (lambda () (sieve (sift hd (stream-rest st))))))

;; stream of prime numbers
(: primes stream)
(define primes (sieve (count-from 2)))

;; Compute the 10,000th prime number


(: main (-> Void))
(define (main)
  (let ([N-1 (read)])
    (unless (exact-nonnegative-integer? N-1)
      (error 'invalid-input "~a" N-1))
    (display (stream-get primes N-1))
    (newline)))

(time (main))
