#lang racket/base

(require racket/flonum)

(require "point.rkt"
         "math.rkt")

(provide make-sphere
         sphere-color
         sphere-radius
         sphere-center
         sphere-normal)


(define (make-sphere color radius center) 
  (vector color radius center))

(define (sphere-color s) 
  (vector-ref s 0))

(define (sphere-radius s) 
  (vector-ref s 1))

(define (sphere-center s) 
  (vector-ref s 2))

(define (sphere-normal s pt) 
  (let ([c (sphere-center s)])
    (unit-vector (fl- (point-x c) (point-x pt))
                 (fl- (point-y c) (point-y pt))
                 (fl- (point-z c) (point-z pt)))))
