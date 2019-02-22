#lang typed/racket/base
;;; 9/27/2017 added types to support typed-racket by Andre Kuhlenschmidt
;;; 10/9/2017 changed to use internal timing (Andre)
;;;
;;; We actively choose to not use racket racket/fixnum. Use of generic
;;; numeric ops is disadvantage for racket but there is no safe
;;; version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)

(require require-typed-check)

(require racket/flonum)

(require/typed/check "blackscholes.rkt"
  [black-scholes (Flonum Flonum Flonum Flonum Flonum Integer Flonum -> Flonum)])

(define-type Stock-Option
  (Vector Flonum Flonum Flonum
          Flonum Flonum Flonum Char
          Flonum Flonum))
(: make-option :
   Flonum Flonum Flonum Flonum Flonum Flonum Char Flonum Flonum -> Stock-Option)
(define (make-option spot-price strike-price rfi-rate
                     divr volatility time option-type
                     divs DerivGem-value)
  (vector spot-price strike-price rfi-rate
          divr volatility time option-type
          divs DerivGem-value))

(: read-option-type : -> Char)
(define (read-option-type)
  (let ([c (read-char)])
    (when (eof-object? c)
      (error 'blackscholes.rkt "invalid input: expected option type"))
    (if (= (char->integer c) (char->integer #\P))
        c
        (if (= (char->integer c) (char->integer #\C))
            c
            (if (= (char->integer c) (char->integer #\space))
                (read-option-type)
                (error 'blackscholes.rkt "invalid input: expected option type"))))))

(: read-option : -> Stock-Option)
(define (read-option)
  (let ([spot-price (read)])
    (let ([strike-price  (read)])
      (let ([rfi-rate (read)])
        (let ([dividend-rate (read)])
          (let ([volatility (read)])
            (let ([maturity-len (read)])
              (let ([option-type (read-option-type)])
                (let ([divs (read)])
                  (let ([DerivGem-value (read)])
                    ;; have to add this for type-checking
                    (unless (and (flonum? spot-price)
                                 (flonum? strike-price)
                                 (flonum? rfi-rate)
                                 (flonum? dividend-rate)
                                 (flonum? volatility)
                                 (flonum? maturity-len)
                                 (flonum? divs)
                                 (flonum? DerivGem-value))
                      (error 'blackscholes.rkt "invalid input: expected stock option"))
                    (make-option spot-price strike-price rfi-rate
                                 dividend-rate volatility maturity-len
                                 option-type divs DerivGem-value)))))))))))

(define number-of-runs : Integer 100)

(define (run-benchmark)
  (define number-of-options : Integer 
    (let ([n : Any (read)])
      (unless (fixnum? n)
        (error 'blackscholes.rkt
               "invalid input: expected fixnum number of options"))
      n))

  (define fake-data : Stock-Option
    '#(#i0 #i0 #i0 #i0 #i0 #i0 #\P #i0 #i0))

  (define data : (Vectorof Stock-Option)
    (let ([v (make-vector number-of-options fake-data)])
      (for ([i (in-range 0 number-of-options)])
        (vector-set! v i (read-option)))
      v))
  

  ;; This seems really dumb but I am doing it because
  ;; this is the way the original benchmark did it.
  (define spots : (Vectorof Flonum) (make-vector number-of-options #i0))
  (define strikes : (Vectorof Flonum) (make-vector number-of-options #i0))
  (define rates  : (Vectorof Flonum) (make-vector number-of-options #i0))
  (define volatilities : (Vectorof Flonum) (make-vector number-of-options #i0))
  (define otypes : (Vectorof Integer) (make-vector number-of-options 0))
  (define otimes : (Vectorof Flonum)
    ;; This is done this way to prevent the unit value
    ;; from printing out at the top level.
    (let ([otimes : (Vectorof Flonum) (make-vector number-of-options #i0)])
      (for ([i (in-range 0 number-of-options)])
        (let ([od : Stock-Option (vector-ref data i)])
          (vector-set! otypes i
                       (if (= (char->integer (vector-ref od 6))
                              (char->integer #\P))
                           1
                           0))
          (vector-set! spots i (vector-ref od 0))
          (vector-set! strikes i (vector-ref od 1))
          (vector-set! rates i (vector-ref od 2))
          (vector-set! volatilities i (vector-ref od 4))
          (vector-set! otimes i (vector-ref od 5))))
      otimes))

  (define prices : (Vectorof Flonum)
    (let ([prices : (Vectorof Flonum) (make-vector number-of-options #i0)])
      (for* ([j (in-range 0 number-of-runs)]
             [i (in-range 0 number-of-options)])
        (vector-set! prices i
                     (black-scholes (vector-ref spots i)
                                    (vector-ref strikes i)
                                    (vector-ref rates i)
                                    (vector-ref volatilities i)
                                    (vector-ref otimes i)
                                    (vector-ref otypes i)
                                    #i0)))
      prices))
  (for ([i (in-range 0 number-of-options)])
    (display (real->decimal-string (vector-ref prices i) 18))
    (newline)))

(time (run-benchmark))
