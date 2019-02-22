#lang racket/base
;;; RAY -- Ray-trace a simple scene with spheres.
;;; Translated to Scheme from Paul Graham's book ANSI Common Lisp, Example 9.8
;;; And then translated to Racket by Deyaaeldeen Almahallawi

;;; Here we use racket/flonum but not racket/fixnum
;;; Use of generic numeric ops is disadvantage for racket
;;; but there is no safe version of fixnum ops that provides
;;; non-contracted ops and we are trying to compare safe code. 
;;; These safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)
;;; -andre

(require racket/flonum)

(require "point.rkt")

(provide sq
         mag
         unit-vector
         distance)

(define (sq x) (fl* x x))

(define (mag x y z) 
  (flsqrt (fl+ (sq x) (fl+ (sq y) (sq z)))))

(define (unit-vector x y z) 
  (let ([d  (mag x y z)])
    (make-point (fl/ x d) (fl/ y d) (fl/ z d))))

(define (distance p1 p2) 
  (mag (fl- (point-x p1) (point-x p2))
       (fl- (point-y p1) (point-y p2))
       (fl- (point-z p1) (point-z p2))))
