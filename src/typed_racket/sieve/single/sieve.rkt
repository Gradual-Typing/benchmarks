#lang typed/racket/base

;; Use the partner file "streams.rkt" to implement the Sieve of Eratosthenes.
;; Then compute and print the 10,000th prime number.

;; ;; A stream is a cons of a value and a thunk that computes the next value when applied
(define-type stream (Rec s (Pair Natural (-> s))))

(: stream-first : stream -> Natural)
(define stream-first car)

(: stream-rest : stream -> stream)
(define (stream-rest st) ((cdr st)))

;;--------------------------------------------------------------------------------------------------

(: make-stream (-> Natural (-> stream) stream))
(define (make-stream hd thunk)
  (cons hd thunk))

;; Destruct a stream into its first value and the new stream produced
;; by de-thunking the tail
(: stream-unfold (-> stream (Pair Natural stream)))
(define (stream-unfold st)
  (cons (stream-first st) (stream-rest st)))

;; [stream-get st i] Get the [i]-th element from the stream [st]
(: stream-get (-> stream Natural Natural))
(define (stream-get st i)
  (cond
    [(= i 0) (stream-first st)]
    [else (stream-get (stream-rest st) (sub1 i))]))

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
