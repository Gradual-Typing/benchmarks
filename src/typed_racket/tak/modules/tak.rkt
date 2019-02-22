#lang typed/racket/base

(provide tak)

;;; TAK -- A vanilla version of the TAKeuchi function.

(: tak : Integer Integer Integer -> Integer)
(define (tak x y z)
  (if (>= y x)
      z
      (tak (tak (- x 1) y z)
           (tak (- y 1) z x)
           (tak (- z 1) x y))))
