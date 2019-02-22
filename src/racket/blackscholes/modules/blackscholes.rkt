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

(provide black-scholes)

(define inv-sqrt-2x-pi 0.39894228040143270286)

(define (cummulative-normal-distribution InputX)
  (let ([sign (fl< InputX #i0.0)]
        [x-input (if (fl< InputX #i0.0) (fl* InputX #i-1.0) InputX)])
    (let ([exp-values (flexp (fl* #i-0.5 (fl* x-input x-input)))])
      (let ([n-prime-of-x (fl* exp-values inv-sqrt-2x-pi)]
            [x-k2 (fl/ #i1.0 (fl+ #i1.0 (fl* #i0.2316419 x-input)))])
        (let ([x-k2^2 (fl* x-k2 x-k2)])
          (let ([x-k2^3 (fl* x-k2^2 x-k2)])
            (let ([x-k2^4 (fl* x-k2^3 x-k2)])
              (let ([x-k2^5 (fl* x-k2^4 x-k2)])
                (let ([x1 (fl* 0.319381530  x-k2)]
                      [x2 (fl* -0.356563782 x-k2^2)]
                      [x3 (fl* 1.781477937  x-k2^3)]
                      [x4 (fl* -1.821255978 x-k2^4)]
                      [x5 (fl* 1.330274429  x-k2^5)])
                  (let ([x (fl+ x1 (fl+ x5 (fl+ x4 (fl+ x2 x3))))])
                    (let ([x (fl- #i1.0 (fl* x n-prime-of-x))])
                      (let ([OutputX (if sign (fl- #i1.0 x) x)])
                        OutputX))))))))))))

(define (black-scholes spot strike rate volatility time option-type timet)
  (let ([log (fllog (fl/ spot strike))]
        [pow (fl* #i0.5 (fl* volatility volatility))]
        [den (fl* volatility (flsqrt time))])
    (let ([d1 (fl/ (fl+ log (fl* time (fl+ rate pow))) den)])
      (let ([d2 (fl- d1 den)])
        (let ([n-of-d1 (cummulative-normal-distribution d1)]
              [n-of-d2 (cummulative-normal-distribution d2)]
              [fut-value (fl* strike (flexp (fl* #i-1 (fl* rate time))))])
          (let ([price (if (= option-type 0)
                           (fl- (fl* spot n-of-d1) (fl* fut-value n-of-d2))
                           (fl- (fl* fut-value (fl- #i1.0 n-of-d2))
                                (fl* spot (fl- #i1.0 n-of-d1))))])
            price))))))


