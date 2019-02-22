#lang typed/racket/base

(require require-typed-check)

(require racket/flonum)

(define-type Body (Vector Flonum Flonum Flonum Flonum Flonum Flonum Flonum))

(require/typed/check "body.rkt"
  [make-body (Flonum Flonum Flonum Flonum Flonum Flonum Flonum -> Body)])

(provide +solar-mass+
         +dt+
         *system*
         *system-size* )

(define +pi+ : Flonum 3.141592653589793) ;; define locally to enable inlining
(define +days-per-year+ : Flonum 365.24)

(define +solar-mass+ : Flonum (fl* 4.0 (fl* +pi+ +pi+)))

(define +dt+ : Flonum 0.01)

(define *sun* : Body
  (make-body 0.0 0.0 0.0 0.0 0.0 0.0 +solar-mass+))

(define *jupiter* : Body
  (make-body 4.84143144246472090
             -1.16032004402742839
             -1.03622044471123109e-1
             (fl* 1.66007664274403694e-3 +days-per-year+)
             (fl* 7.69901118419740425e-3 +days-per-year+)
             (fl* -6.90460016972063023e-5 +days-per-year+)
             (fl* 9.54791938424326609e-4 +solar-mass+)))

(define *saturn* : Body
  (make-body 8.34336671824457987
             4.12479856412430479
             -4.03523417114321381e-1
             (fl* -2.76742510726862411e-3 +days-per-year+)
             (fl* 4.99852801234917238e-3 +days-per-year+)
             (fl* 2.30417297573763929e-5 +days-per-year+)
             (fl* 2.85885980666130812e-4 +solar-mass+)))

(define *uranus* : Body
  (make-body 1.28943695621391310e1
             -1.51111514016986312e1
             -2.23307578892655734e-1
             (fl* 2.96460137564761618e-03 +days-per-year+)
             (fl* 2.37847173959480950e-03 +days-per-year+)
             (fl* -2.96589568540237556e-05 +days-per-year+)
             (fl*  4.36624404335156298e-05 +solar-mass+)))

(define *neptune* : Body
  (make-body 1.53796971148509165e+01
             -2.59193146099879641e+01
             1.79258772950371181e-01
             (fl* 2.68067772490389322e-03 +days-per-year+)
             (fl* 1.62824170038242295e-03 +days-per-year+)
             (fl* -9.51592254519715870e-05 +days-per-year+)
             (fl* 5.15138902046611451e-05 +solar-mass+)))

(define-type System (Vector Body Body Body Body Body))
(define *system* : System (vector *sun* *jupiter* *saturn* *uranus* *neptune*))
(define *system-size* : Integer 5)
