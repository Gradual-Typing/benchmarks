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

(require "point.rkt"
         "math.rkt"
         "sphere.rkt"
         "helper.rkt")

(define *world* (make-vector 33 (vector 0.0 0.0 (vector 0.0 0.0 0.0))))

(define eye (make-point 0.0 0.0 200.0))

(define (tracer res)
  (let ([extent (* res 100)])
    (display "P2 ")
    (write extent)
    (display " ")
    (write extent)
    (display " 255")
    (newline)
    (do ((y 0 (+ y 1)))
        ((= y extent))
      (do ((x 0 (+ x 1)))
          ((= x extent))
        (write (color-at
                (fl+ -50.0
                     (fl/ (exact->inexact x) (exact->inexact res)))
                (fl+ -50.0
                     (fl/ (exact->inexact y) (exact->inexact res)))))
        (newline)))))

(define (color-at x y)
  (let ([ray (unit-vector (fl- x (point-x eye))
                          (fl- y (point-y eye))
                          (fl* -1.0 (point-z eye)))])
    (inexact->exact (flround (fl* (sendray eye ray) 255.0)))))

(define (sendray pt ray)
  (let ([x (loop pt ray 0
                 (vector-length *world*)
                 *world*
                 #f
                 #f
                 1e308)])
    (let ([s (vector-ref x 0)]
          [int (vector-ref x 1)])
      (if s
          (fl* (lambert s int ray)
               (sphere-color s))
          0.0))))

(define (lambert s int ray)
  (let ([n (sphere-normal s int)])
    (flmax 0.0
           (fl+ (fl* (point-x ray) (point-x n))
                (fl+ (fl* (point-y ray) (point-y n))
                     (fl* (point-z ray) (point-z n)))))))

(define (defsphere i x y z r c) 
  (let ([s (make-sphere c r (make-point x y z))])
    (begin
      (vector-set! *world* i s)
      s)))

(define (main)
  (let ([res (read)])
    (let ([counter (box 29)])
      (begin
        (defsphere 32 0.0 -300.0 -1200.0 200.0 0.8)
        (defsphere 31 -80.0 -150.0 -1200.0 200.0 0.7)
        (defsphere 30 70.0 -100.0 -1200.0 200.0 0.9)
        (do ((x -2 (+ x 1)))
            ((> x 2))
          (do ((z 2 (+ z 1)))
              ((> z 7))
            (defsphere
              (unbox counter)
              (fl* (exact->inexact x) 200.0)
              300.0
              (fl* (exact->inexact z) -400.0)
              40.0
              0.75)
            (set-box! counter (- (unbox counter) 1))))))
    (tracer res)))

(time (main))
