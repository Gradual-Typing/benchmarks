#lang typed/racket/base
;;; We actively choose to not use racket racket/fixnum. Use of generic
;;; numeric ops is disadvantage for racket but there is no safe
;;; version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)

;;; 9/27/2017 - added types for typed racket
;;; 10/9/2017 - added internal timing to midigate cost of startup

(require racket/pretty)

(require require-typed-check)

(require/typed/check "tak.rkt" [tak (Integer Integer Integer -> Integer)])

(define (main)
  (let* ([x : Any (read)]
         [y : Any (read)]
         [z : Any (read)])
    ;; These fixnum? checks are additional work that the original dynamic
    ;; code didn't have to do. Is there any way of making it disappear?
    (unless (and (fixnum? x) (fixnum? y) (fixnum? z))
      (error 'invalid-input "expected 3 fixnum values"))
    (pretty-print (tak x y z))))

(time (main))
