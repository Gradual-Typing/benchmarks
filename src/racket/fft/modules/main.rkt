#lang racket/base
;;; FFT - Fast Fourier Transform, translated from "Numerical Recipes in C"

;;; Here we actively choose to not use racket racket/fixnum. Use of
;;; generic numeric ops is disadvantage for racket but there is no
;;; safe version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)

(require racket/flonum)

(require "loop1.rkt")

(define (loop3 mmax size data)
  (if (< mmax size)
      (let ([theta (fl/ pi*2 (exact->inexact mmax))])
        (let ([wpr (let ([x (flsin (fl* #i0.5 theta))])
                     (fl* #i-2.0 (fl* x x)))]
              [wpi (flsin theta)])
          (loop4 #i1.0 #i0.0 0 mmax wpr wpi size data)
          (loop3 (* mmax 2) size data)))
      (void)))

(define (loop4 wr wi m mmax wpr wpi size data)
  (if (< m mmax)
      (loop5 m mmax wr wi m wpr wpi size data)
      (void)))

(define (loop5 i mmax wr wi m wpr wpi size data)
  (if (< i size)
      (let ([j (+ i mmax)])
        (let ([tempr
               (fl-
                (fl* wr (vector-ref data j))
                (fl* wi (vector-ref data (+ j 1))))]
              [tempi
               (fl+
                (fl* wr (vector-ref data (+ j 1)))
                (fl* wi (vector-ref data j)))])
          (vector-set! data j
                       (fl- (vector-ref data i) tempr))
          (vector-set! data (+ j 1)
                       (fl- (vector-ref data (+ i 1)) tempi))
          (vector-set! data i
                       (fl+ (vector-ref data i) tempr))
          (vector-set! data (+ i 1)
                       (fl+ (vector-ref data (+ i 1)) tempi))
          (loop5 (+ j mmax) mmax wr wi m wpr wpi size data)))
      (loop4 (fl+ (fl- (fl* wr wpr) (fl* wi wpi)) wr)
             (fl+ (fl+ (fl* wi wpr) (fl* wr wpi)) wi)
             (+ m 2)
             mmax wpr wpi size data)))

(define (main)
  (define n (read))
  (define data (make-vector n #i0.0))
  (loop1 0 0 n data) ;; bit-reversal section
  (loop3 2 n data)   ;; Danielson-Lanczos section
  (display (real->decimal-string (vector-ref data 0))))

(time (main))
