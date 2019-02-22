#lang racket/base
;; Black-Scholes
;; Analytical method for calculating European Options
;;
;;
;; Reference Source: Options, Futures, and Other Derivatives,
;;   3rd Edition, Prentice Hall, John C. Hull,
;; Edited for use in The Grift Benchmark Project By Andre Kuhlenschmidt

;;; Here we actively choose to not use racket racket/fixnum. Use of
;;; generic numeric ops is disadvantage for racket but there is no
;;; safe version of fixnum operations that avoids the overhead of
;;; contracts, and we are only interested in comparing safe code.  The
;;; racket/fixnum safe operations are generally no faster than using
;;; generic primitives like +. (According to the documentation)
(require racket/flonum)

(require "blackscholes.rkt")


(define (make-option spot-price strike-price rfi-rate
                     divr volatility time option-type
                     divs DerivGem-value)
  (vector spot-price strike-price rfi-rate
          divr volatility time option-type
          divs DerivGem-value))

(define (read-option-type)
  (let ([c (read-char)])
    (if (= (char->integer c) (char->integer #\P))
        c
        (if (= (char->integer c) (char->integer #\C))
            c
            (if (= (char->integer c) (char->integer #\space))
                (read-char)
                (read-char))))));; raise error?

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
                    (make-option spot-price strike-price rfi-rate
                                 dividend-rate volatility maturity-len
                                 option-type divs DerivGem-value)))))))))))

(define number-of-runs 100)

(define (run-benchmark)
  (define number-of-options (read))

  (define fake-data '#(#i0 #i0 #i0 #i0 #i0 #i0 #\P #i0 #i0))

  (define data
    (let ([v (make-vector number-of-options fake-data)])
      (for ([i (in-range 0 number-of-options)])
        (vector-set! v i (read-option)))
      v))
  

  ;; This seems really dumb but I am doing it because
  ;; this is the way the original benchmark did it.
  (define spots (make-vector number-of-options #i0))
  (define strikes (make-vector number-of-options #i0))
  (define rates  (make-vector number-of-options #i0))
  (define volatilities  (make-vector number-of-options #i0))
  (define otypes (make-vector number-of-options 0))
  (define otimes 
    ;; This is done this way to prevent the unit value
    ;; from printing out at the top level.
    (let ([otimes (make-vector number-of-options #i0)])
      (for ([i (in-range 0 number-of-options)])
        (let ([od (vector-ref data i)])
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

  (define prices 
    (let ([prices (make-vector number-of-options #i0)])
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


