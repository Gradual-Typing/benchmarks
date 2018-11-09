#!gsi-script
(declare (standard-bindings) (extended-bindings) (block))

(define stream-first car)

(define (stream-rest st) ((cdr st)))

(define (make-stream hd thunk)
  (cons hd thunk))

(define (stream-unfold st)
  (cons (stream-first st) (stream-rest st)))

(define (stream-get st i)
  (cond
   [(fx= i 0) (stream-first st)]
   [else (stream-get (stream-rest st) (fx- i 1))]))

(define (count-from n)
  (make-stream n (lambda () (count-from (fx+ n 1)))))

;; `sift n st` Filter all elements in `st` that are equal to `n`.
;; Return a new stream.
(define (sift n st)
  (define hd (stream-first st))
  (cond
    [(fx= 0 (fxmodulo hd n))
     (sift n (stream-rest st))]
    [else
     (make-stream hd (lambda () (sift n (stream-rest st))))]))

;; `sieve st` Sieve of Eratosthenes
(define (sieve st)
  (define hd (stream-first st))
  (make-stream hd (lambda () (sieve (sift hd (stream-rest st))))))

;; stream of prime numbers
(define primes (sieve (count-from 2)))

(define (run-benchmark)
  (let ([N-1 (read)])
    (display (stream-get primes N-1))
    (newline)))

(time (run-benchmark) (current-output-port))
