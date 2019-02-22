#lang racket/base

(require racket/flonum)

(provide make-point
         point-x
         point-y
         point-z )

(define (make-point x y z)
  (vector x y z))

(define (point-x p) (vector-ref p 0))

(define (point-y p) (vector-ref p 1))

(define (point-z p) (vector-ref p 2))
