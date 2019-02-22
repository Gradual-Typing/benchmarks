#lang typed/racket/base

;; Simple streams library.
;; For building and using infinite lists.

(provide
 stream
 make-stream
 stream-first
 stream-rest
 stream-unfold
 stream-get)

;; A stream is a cons of a value and a thunk that computes the next value when applied
(define-type stream (Rec s (Pair Natural (-> s))))

(: stream-first : stream -> Natural)
(define stream-first car)

(: stream-rest : stream -> stream)
(define (stream-rest st) ((cdr st)))

;;--------------------------------------------------------------------------------------------------

(: make-stream (-> Natural (-> stream) stream))
(define (make-stream hd thunk)
  (cons hd thunk))

;; Destruct a stream into its first value and the new stream produced
;; by de-thunking the tail
(: stream-unfold (-> stream (Pair Natural stream)))
(define (stream-unfold st)
  (cons (stream-first st) (stream-rest st)))

;; [stream-get st i] Get the [i]-th element from the stream [st]
(: stream-get (-> stream Natural Natural))
(define (stream-get st i)
  (cond
    [(= i 0) (stream-first st)]
    [else (stream-get (stream-rest st) (sub1 i))]))
