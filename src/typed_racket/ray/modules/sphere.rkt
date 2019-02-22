#lang typed/racket/base

(require require-typed-check)

(require racket/flonum)

(define-type Point (Vector Flonum Flonum Flonum))

(require/typed/check "point.rkt"
                     [make-point (Flonum Flonum Flonum -> Point)]
                     [point-x (Point -> Flonum)]
                     [point-y (Point -> Flonum)]
                     [point-z (Point -> Flonum)])

(require/typed/check "math.rkt"
                     [sq (Flonum -> Flonum)]
                     [mag (Flonum Flonum Flonum -> Flonum)]
                     [unit-vector (Flonum Flonum Flonum -> Point)]
                     [distance (Point Point -> Float)])

(provide make-sphere
         sphere-color
         sphere-radius
         sphere-center
         sphere-normal)

(define-type Color Flonum)
(define-type Radius Flonum)
(define-type Sphere (Vector Color Radius Point))

(: make-sphere : Color Radius Point -> Sphere)
(define (make-sphere color radius center) 
  (vector color radius center))

(: sphere-color : Sphere -> Color)
(define (sphere-color s) 
  (vector-ref s 0))

(: sphere-radius : Sphere -> Radius)
(define (sphere-radius s) 
  (vector-ref s 1))

(: sphere-center : Sphere -> Point)
(define (sphere-center s) 
  (vector-ref s 2))

(: sphere-normal : Sphere Point -> Point)
(define (sphere-normal s pt) 
  (let ([c (sphere-center s)])
    (unit-vector (fl- (point-x c) (point-x pt))
                 (fl- (point-y c) (point-y pt))
                 (fl- (point-z c) (point-z pt)))))
