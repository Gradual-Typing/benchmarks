#lang racket/base

;; Simple streams library.
;; For building and using infinite lists.

(provide
 make-stream
 stream-first
 stream-rest
 stream-unfold
 stream-get)


(define stream-first car)

(define (stream-rest st) ((cdr st)))

;;--------------------------------------------------------------------------------------------------

(define (make-stream hd thunk)
  (cons hd thunk))

;; Destruct a stream into its first value and the new stream produced
;; by de-thunking the tail
(define (stream-unfold st)
  (cons (stream-first st) (stream-rest st)))

;; [stream-get st i] Get the [i]-th element from the stream [st]
(define (stream-get st i)
  (cond
    [(= i 0) (stream-first st)]
    [else (stream-get (stream-rest st) (sub1 i))]))
