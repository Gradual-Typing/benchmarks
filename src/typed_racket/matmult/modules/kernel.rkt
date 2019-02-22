#lang typed/racket/base

(provide mult)

(: mult : (Vectorof Integer) Integer Integer (Vectorof Integer) Integer Integer
   -> (Vectorof Integer))
(define (mult x x1 x2 y y1 y2)
  (let ([r : (Vectorof Integer) (make-vector (* y2 x1) 0)])
    (let loop1 ([i 0])
      (if (< i x1)
          (let loop2 ([j 0])
            (if (< j y2)
                (let loop3 ([k 0])
                  (if (< k y1)
                      (begin
                        (vector-set! r (+ (* i y2) j)
                                     (+ (vector-ref r (+ (* i y2) j))
                                          (*
                                           (vector-ref x (+ (* i x2) k))
                                           (vector-ref y (+ (* k y2) j)))))
                        (loop3 (+ k 1)))
                      (loop2 (+ j 1))))
                (loop1 (+ i 1))))
          r))))
