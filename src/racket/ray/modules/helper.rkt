#lang racket/base

(require racket/flonum)

(require "point.rkt"
         "math.rkt"
         "sphere.rkt")

(provide loop)

(define (loop pt ray index lst-len lst surface hit dist)
  (if (= index lst-len)
      (vector surface hit)
      (let ([s (vector-ref lst index)])
        (let ([xr  (point-x ray)]
              [yr  (point-y ray)]
              [zr  (point-z ray)]
              [sc  (sphere-center s)])
          (let ([a  (fl+ (sq xr) (fl+ (sq yr) (sq zr)))]
                [b  (fl* 2.0
                         (fl+ (fl* (fl- (point-x pt) (point-x sc)) xr)
                              (fl+ (fl* (fl- (point-y pt) (point-y sc)) yr)
                                   (fl* (fl- (point-z pt) (point-z sc)) zr))))]
                [c  (fl+ (fl+ (sq (fl- (point-x pt) (point-x sc)))
                              (sq (fl- (point-y pt) (point-y sc))))
                         (fl+ (sq (fl- (point-z pt) (point-z sc)))
                              (fl* -1.0 (sq (sphere-radius s)))))])
            (if (zero? a)
                (let ([n  (fl/ (fl* -1.0 c) b)])
                  (let ([h (make-point (fl+ (point-x pt) (fl* n xr))
                                       (fl+ (point-y pt) (fl* n yr))
                                       (fl+ (point-z pt) (fl* n zr)))])
                    (let ([d (distance h pt)])
                      (if (fl< d dist)
                          (loop pt ray (+ index 1) lst-len lst s h d)
                          (loop pt ray (+ index 1) lst-len lst surface hit dist)))))
                (let ([disc (fl- (sq b) (fl* 4.0 (fl* a c)))])
                  (if (negative? disc)
                      (loop pt ray (+ index 1) lst-len lst surface hit dist)
                      (let ([discrt  (flsqrt disc)]
                            (minus-b  (fl* -1.0 b))
                            (two-a  (fl* 2.0 a)))
                        (let ([n (flmin (fl/ (fl+ minus-b discrt) two-a)
                                        (fl/ (fl- minus-b discrt) two-a))])
                          (let ([h (make-point (fl+ (point-x pt) (fl* n xr))
                                               (fl+ (point-y pt) (fl* n yr))
                                               (fl+ (point-z pt) (fl* n zr)))])
                            (let ([d (distance h pt)])
                              (if (fl< d dist)
                                  (loop pt ray (+ index 1) lst-len lst s h d)
                                  (loop pt ray (+ index 1) lst-len lst surface hit dist))))))))))))))
