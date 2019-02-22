#lang typed/racket/base

(require require-typed-check)

(provide partition)

(: partition : (Vectorof Integer) Integer Integer -> Integer)
(define (partition a p r)
  ;; Why does this box exist?
  (let ([i : (Boxof Integer) (box (- p 1))]
        [x (vector-ref a r)])
    (begin
      (let loop : Integer ([j : Integer p])
       (if (< j r)
           (begin
             (if (<= (vector-ref a j) x)
                 (begin
                   (set-box! i (+ (unbox i) 1))
                   (swap a (unbox i) j))
                 0)
             (loop (+ j 1)))
           0))
      (swap a (+ (unbox i) 1) r)
      (+ (unbox i) 1))))

(: swap : (Vectorof Integer) Integer Integer -> Integer)
(define (swap a i j)
  (if (= i j)
      0
      (let ([t (vector-ref a i)])
        (begin
          (vector-set! a i (vector-ref a j))
          (vector-set! a j t)
          0))))
