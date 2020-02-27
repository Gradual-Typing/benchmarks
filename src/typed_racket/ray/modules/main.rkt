#lang typed/racket/base

(require require-typed-check)

(require racket/flonum racket/format)

;;; RAY -- Ray-trace a simple scene with spheres.
;;; Translated to Scheme from Paul Graham's book ANSI Common Lisp, Example 9.8
;;;
;;; And then translated to Racket by Deyaaeldeen Almahallawi
;;; We actively choose to not use racket racket/fixnum. Use of generic
;;; numeric ops is disadvantage for racket but there is no safe
;;; version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)
;;;
;;; 9/27/2017 Added types for typed-racket Andre Kuhlenschmidt
;;; 10/9/2017 changed to use internal timing (Andre)

(define-type Point (Vector Flonum Flonum Flonum))
(define-type Color Flonum)
(define-type Radius Flonum)
(define-type Sphere (Vector Color Radius Point))
(define-type Surface (Vector Flonum Flonum Point))
(define-type World (Vectorof Surface))
(define-type Loop-Result (Vector (Option Surface) (Option Point)))

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

(require/typed/check "sphere.rkt"
                     [make-sphere (Color Radius Point -> Sphere)]
                     [sphere-color (Sphere -> Color)]
                     [sphere-radius (Sphere -> Radius)]
                     [sphere-center (Sphere -> Point)]
                     [sphere-normal (Sphere Point -> Point)])

(require/typed/check "helper.rkt"
                     [loop (Point Point Integer Integer World (Option Surface) (Option Point) Flonum
     -> Loop-Result)])

(define *world* (make-vector 33 (vector 0.0 0.0 (vector 0.0 0.0 0.0))))

(: eye : Point)
(define eye (make-point 0.0 0.0 200.0))

(: defsphere : Integer Flonum Flonum Flonum Radius Color -> Sphere)
(define (defsphere i x y z r c) 
  (let ([s (make-sphere c r (make-point x y z))])
    (begin
      (vector-set! *world* i s)
      s)))

(: tracer : Integer -> Void)
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
                     (fl/ (->fl x) (->fl res)))
                (fl+ -50.0
                     (fl/ (->fl y) (->fl res)))))
        (newline)))))

(: color-at : Flonum Flonum -> Integer)
(define (color-at x y)
  (let ([ray (unit-vector (fl- x (point-x eye))
                          (fl- y (point-y eye))
                          (fl* -1.0 (point-z eye)))])
    (fl->exact-integer (flround (fl* (sendray eye ray) 255.0)))))

(: sendray : Point Point -> Flonum)
(define (sendray pt ray)
  (let ([x : Loop-Result
           (loop pt ray 0
                 (vector-length *world*)
                 *world*
                 #f
                 #f
                 1e308)])
    (let ([s (vector-ref x 0)]
          [int (vector-ref x 1)])
      ;; Had to add check of int to make type correct
      (if (and s int)
          (fl* (lambert s int ray)
               (sphere-color s))
          0.0))))

(: lambert : Sphere Point Point -> Flonum)
(define (lambert s int ray)
  (let ([n (sphere-normal s int)])
    (flmax 0.0
           (fl+ (fl* (point-x ray) (point-x n))
                (fl+ (fl* (point-y ray) (point-y n))
                     (fl* (point-z ray) (point-z n)))))))

(: main : -> Void)
(define (main)
  (let ([res (read)])
    (let ([counter : (Boxof Integer) (box 29)])
      (unless (exact-nonnegative-integer? res)
        (error 'invalid-input "~a" res))
      (begin
        (defsphere 32 0.0 -300.0 -1200.0 200.0 0.8)
        (defsphere 31 -80.0 -150.0 -1200.0 200.0 0.7)
        (defsphere 30 70.0 -100.0 -1200.0 200.0 0.9)
        (do : Void
          ((x : Integer -2 (+ x 1)))
          ((> x 2))
          (do : Void ((z : Integer 2 (+ z 1)))
              ((> z 7))
              (defsphere
                (unbox counter)
                (fl* (->fl x) 200.0)
                300.0
                (fl* (->fl z) -400.0)
                40.0
                0.75)
              (set-box! counter (- (unbox counter) 1))))))
    (tracer res)))

(time (main))
