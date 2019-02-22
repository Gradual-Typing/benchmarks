#lang racket/base

(require racket/flonum)

(require "system.rkt")

(provide energy)

(define (energy)
  (let loop-o ([o 0] [e 0.0])
    (if (= o *system-size*)
        e
        (let* ([o1 (vector-ref *system* o)]
               [e (fl+ e (fl* (fl* 0.5 (vector-ref o1 6))
                              (fl+ (fl+ (fl* (vector-ref o1 3) (vector-ref o1 3))
                                        (fl* (vector-ref o1 4) (vector-ref o1 4)))
                                   (fl* (vector-ref o1 5) (vector-ref o1 5)))))])
          (let loop-i ([i (+ o 1)] [e e])
            (if (= i *system-size*)
                (loop-o (+ o 1) e)
                (let* ([i1   (vector-ref *system* i)]
                       [dx   (fl- (vector-ref o1 0) (vector-ref i1 0))]
                       [dy   (fl- (vector-ref o1 1) (vector-ref i1 1))]
                       [dz   (fl- (vector-ref o1 2) (vector-ref i1 2))]
                       [dist (flsqrt (fl+ (fl+ (fl* dx dx) (fl* dy dy)) (fl* dz dz)))]
                       [e    (fl- e (fl/ (fl* (vector-ref o1 6) (vector-ref i1 6)) dist))])
                  (loop-i (+ i 1) e))))))))
    
