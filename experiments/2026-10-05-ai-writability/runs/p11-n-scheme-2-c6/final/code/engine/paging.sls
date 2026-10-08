;;; (engine paging) -- LIMIT and OFFSET (spec 1.7), for simple and compound selects alike.
(library (engine paging)
  (export constant-integer page-rows)
  (import (rnrs) (engine values) (engine expr))

  ;; The integer a LIMIT/OFFSET expression gives (no row in scope).
  (define (constant-integer db expr)
    (let ([v ((cexpr-proc (compile-expr expr (make-scope (make-level db '() #f) '()))) (vector))])
      (cond [(sql-null? v) 0]
            [(string? v) (integer-of (text->number-prefix v))]
            [else (integer-of v)])))

  (define (integer-of n) (if (integer-value? n) n (exact (truncate n))))

  (define (drop-rows rows n)
    (let loop ([rows rows] [n n]) (if (or (<= n 0) (null? rows)) rows (loop (cdr rows) (- n 1)))))

  (define (take-rows rows n)
    (let loop ([rows rows] [n n] [acc '()])
      (if (or (<= n 0) (null? rows)) (reverse acc) (loop (cdr rows) (- n 1) (cons (car rows) acc)))))

  ;; Skip `offset` rows, then keep at most `limit` (#f or negative: no limit).
  (define (page-rows rows limit offset)
    (let ([paged (drop-rows rows offset)])
      (if (and limit (>= limit 0)) (take-rows paged limit) paged))))
