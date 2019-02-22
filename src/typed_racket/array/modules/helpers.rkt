#lang typed/racket/base

(provide create-x
         create-y)

(: create-x : Integer -> (Vectorof Integer))
(define (create-x n)
  (define result : (Vectorof Integer) (make-vector n))
  (do : (Vectorof Integer)
    ((i : Integer 0 (+ i 1)))
    ((>= i n) result)
    (vector-set! result i i)))

(: create-y : (Vectorof Integer) -> (Vectorof Integer))
(define (create-y x)
  (let* ((n : Integer (vector-length x))
         (result : (Vectorof Integer) (make-vector n)))
    (do : (Vectorof Integer)
      ((i : Integer (- n 1) (- i 1)))
      ((< i 0) result)
      (vector-set! result i (vector-ref x i)))))
