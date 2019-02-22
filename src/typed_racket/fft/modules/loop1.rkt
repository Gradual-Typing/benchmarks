#lang typed/racket/base
;;; 10/9/2017 changed to use internal timing (Andre)
;;;
;;; We actively choose to not use racket racket/fixnum. Use of generic
;;; numeric ops is disadvantage for racket but there is no safe
;;; version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)

(require racket/flonum)

(provide pi*2
         loop1)

(define pi*2 : Flonum #i6.28318530717959)

(: loop1 : Integer Integer Integer (Vectorof Flonum) -> Void)
  (define (loop1 i j size data)
    (if (< i size)
        (begin
          (if (< i j)
              (begin
                (let ([temp (vector-ref data i)])
                  (begin
                    (vector-set! data i (vector-ref data j))
                    (vector-set! data j temp)))
                (let ([temp (vector-ref data (+ i 1))])
                  (begin
                    (vector-set! data (+ i 1) (vector-ref data (+ j 1)))
                    (vector-set! data (+ j 1) temp))))
              (void))
          (loop2 (quotient size 2) j i size data))
        (void)))

 ; to compute the inverse, negate this value
  (: loop2 : Integer Integer Integer Integer (Vectorof Flonum) -> Void)
  (define (loop2 m j i size data)
    (if (and (>= m 2) (>= j m))
        (loop2 (quotient m 2) (- j m) i size data)
        (loop1 (+ i 2) (+ j m) size data)))
