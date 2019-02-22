#lang typed/racket/base

(require require-typed-check)

(require racket/flonum)

(define-type Body (Vector Flonum Flonum Flonum Flonum Flonum Flonum Flonum))

(require/typed/check "system.rkt"
  [+solar-mass+ Flonum]
  [+dt+ Flonum]
  [*system* (Vector Body Body Body Body Body)]
  [*system-size* Integer])

(provide offset-momentum)

(: offset-momentum : -> Void)
(define (offset-momentum)
  (let loop-i ([i : Integer 0]
               [px : Flonum 0.0]
               [py : Flonum 0.0]
               [pz : Flonum 0.0])
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
