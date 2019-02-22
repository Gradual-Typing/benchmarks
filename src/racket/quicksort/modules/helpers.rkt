#lang racket

(provide partition)

(define (partition a p r)
  (let ([i (box (- p 1))]
	[x (vector-ref a r)])
    (begin
      (let loop ([j p])
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

(define (swap a i j)
  (if (= i j)
      0
      (let ([t (vector-ref a i)])
	(begin
	  (vector-set! a i (vector-ref a j))
	  (vector-set! a j t)
	  0))))
