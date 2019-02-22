#lang racket/base

(require racket/flonum)

(require "system.rkt")

(provide offset-momentum)

(define (offset-momentum)
    (let loop-i ([i 0] [px 0.0] [py 0.0] [pz 0.0])
      (if (= i *system-size*)
          (begin
            (vector-set! (vector-ref *system* 0) 3 (fl/ (fl- 0.0 px) +solar-mass+))
            (vector-set! (vector-ref *system* 0) 4 (fl/ (fl- 0.0 py) +solar-mass+))
            (vector-set! (vector-ref *system* 0) 5 (fl/ (fl- 0.0 pz) +solar-mass+)))
          (let ([i1 (vector-ref *system* i)])
            (loop-i (+ i 1)
                    (fl+ px (fl* (vector-ref i1 3) (vector-ref i1 6)))
                    (fl+ py (fl* (vector-ref i1 4) (vector-ref i1 6)))
                    (fl+ pz (fl* (vector-ref i1 5) (vector-ref i1 6))))))))
    
