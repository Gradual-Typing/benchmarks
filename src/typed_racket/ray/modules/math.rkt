#lang typed/racket/base

(require require-typed-check)

(require racket/flonum)

(define-type Point (Vector Flonum Flonum Flonum))

(require/typed/check "point.rkt"
                     [make-point (Flonum Flonum Flonum -> Point)]
                     [point-x (Point -> Flonum)]
                     [point-y (Point -> Flonum)]
                     [point-z (Point -> Flonum)])

(provide sq
         mag
         unit-vector
         distance)

(: sq : Flonum -> Flonum)
(define (sq x) (fl* x x))

(: mag : Flonum Flonum Flonum -> Flonum)
(define (mag x y z) 
  (flsqrt (fl+ (sq x) (fl+ (sq y) (sq z)))))

(: unit-vector : Flonum Flonum Flonum -> Point)
(define (unit-vector x y z) 
  (let ([d  (mag x y z)])
    (make-point (fl/ x d) (fl/ y d) (fl/ z d))))

(: distance : Point Point -> Float)
(define (distance p1 p2) 
  (mag (fl- (point-x p1) (point-x p2))
       (fl- (point-y p1) (point-y p2))
       (fl- (point-z p1) (point-z p2))))
