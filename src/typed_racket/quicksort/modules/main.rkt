#lang typed/racket/base
;;; 10/9/2017 changed to use internal timing (Andre)
;;;
;;; We actively choose to not use racket racket/fixnum. Use of generic
;;; numeric ops is disadvantage for racket but there is no safe
;;; version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)

(require require-typed-check)

(require/typed/check "helpers.rkt"
                     [partition ((Vectorof Integer) Integer Integer -> Integer)])

(: sort : (Vectorof Integer) Integer Integer -> Integer)
(define (sort a p r)
  (if (< p r)
      (let ([q (partition a p r)])
        (begin
          (sort a p (- q 1))
          (sort a (+ q 1) r)))
      0))

(define (main)
  (let ([size (read)])
    (unless (fixnum? size)
      (error 'quicksort "invalid input: expected fixnum"))
    (let ([a : (Vectorof Integer) (make-vector size 1)])
      (let loop ([i : Integer 0])
        (when (< i size)
          (let ([e (read)])
            (unless (fixnum? e)
              (error 'quicksort.rkt "invalid input: expected integer"))
            (vector-set! a i e)
            (loop (+ i 1)))))
      (sort a 0 (- size 1))
      (display (vector-ref a (- size 1))))))

(time (main))
