#lang racket/base

;; The Computer Language Benchmarks Game
;; http://benchmarksgame.alioth.debian.org/
;;
;; Imperative-style implementation based on the SBCL implementation by
;; Patrick Frankenberger and Juho Snellman, but using only native Scheme
;; idioms like 'named let' and 'do' special form.
;;
;; Contributed by Anthony Borla, then converted for Racket
;; by Matthew Flatt and Brent Fulgham
;; Made unsafe and optimized by Sam TH
;;
;;; Here we actively choose to not use racket racket/fixnum. Use of
;;; generic numeric ops is disadvantage for racket but there is no
;;; safe version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)
#|
Correct output N = 1000 is

-0.169075164
-0.169087605
|#

(require racket/flonum)

(require "system.rkt"
         "momentum.rkt"
         "energy.rkt")

(define (advance)
  (let loop-o ([o 0])
    (unless (= o *system-size*)
      (let* ([o1 (vector-ref *system* o)])
        (let loop-i ([i  (+ o 1)]
                     [vx (vector-ref o1 3)]
                     [vy (vector-ref o1 4)]
                     [vz (vector-ref o1 5)])
          (if (< i *system-size*)
              (let* ([i1    (vector-ref *system* i)]
                     [dx    (fl- (vector-ref o1 0) (vector-ref i1 0))]
                     [dy    (fl- (vector-ref o1 1) (vector-ref i1 1))]
                     [dz    (fl- (vector-ref o1 2) (vector-ref i1 2))]
                     [dist2 (fl+ (fl+ (fl* dx dx) (fl* dy dy)) (fl* dz dz))]
                     [mag   (fl/ +dt+ (fl* dist2 (flsqrt dist2)))]
                     [dxmag (fl* dx mag)]
                     [dymag (fl* dy mag)]
                     [dzmag (fl* dz mag)]
                     [om (vector-ref o1 6)]
                     [im (vector-ref i1 6)])
                (vector-set! i1 3 (fl+ (vector-ref i1 3) (fl* dxmag om)))
                (vector-set! i1 4 (fl+ (vector-ref i1 4) (fl* dymag om)))
                (vector-set! i1 5 (fl+ (vector-ref i1 5) (fl* dzmag om)))
                (loop-i (+ i 1)
                        (fl- vx (fl* dxmag im))
                        (fl- vy (fl* dymag im))
                        (fl- vz (fl* dzmag im))))
              (begin (vector-set! o1 3 vx)
                     (vector-set! o1 4 vy)
                     (vector-set! o1 5 vz)
                     (vector-set! o1 0 (fl+ (vector-ref o1 0) (fl* +dt+ vx)))
                     (vector-set! o1 1 (fl+ (vector-ref o1 1) (fl* +dt+ vy)))
                     (vector-set! o1 2 (fl+ (vector-ref o1 2) (fl* +dt+ vz)))))))
      (loop-o (+ o 1)))))

(define (main)
  (let ([n (read)])
    (offset-momentum)
    (printf "~a\n" (real->decimal-string (energy) 9))
    (for ([i (in-range n)]) (advance))
    (printf "~a\n" (real->decimal-string (energy) 9))))

(time (main))
