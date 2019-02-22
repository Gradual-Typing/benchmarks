#lang typed/racket/base

(require racket/flonum)

(provide make-body)

(define-type Body (Vector Flonum Flonum Flonum Flonum Flonum Flonum Flonum))

(: make-body :  Flonum Flonum Flonum Flonum Flonum Flonum Flonum -> Body)
(define (make-body x y z vx vy vz m)
  (vector x y z vx vy vz m))
