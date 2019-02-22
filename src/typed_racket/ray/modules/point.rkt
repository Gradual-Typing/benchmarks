#lang typed/racket/base

(require require-typed-check)

(require racket/flonum)

(provide make-point
         point-x
         point-y
         point-z )

(define-type Point (Vector Flonum Flonum Flonum))

(: make-point : Flonum Flonum Flonum -> Point)
(define (make-point x y z)
  (vector x y z))

(: point-x : Point -> Flonum)
(define (point-x p) (vector-ref p 0))

(: point-y : Point -> Flonum)
(define (point-y p) (vector-ref p 1))

(: point-z : Point -> Flonum)
(define (point-z p) (vector-ref p 2))
