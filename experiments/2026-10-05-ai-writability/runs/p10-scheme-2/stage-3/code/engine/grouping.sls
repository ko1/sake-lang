;;; (engine grouping) -- equality of values for GROUP BY and DISTINCT (spec 1.9: 1 = 1.0, NULLs equal).
(library (engine grouping)
  (export partition-rows distinct-by)
  (import (rnrs) (engine values))

  ;; A value that is `equal?` exactly when the SQL values are equal.
  (define (value-key v)
    (if (real-value? v) (or (real-whole-int64 v) v) v))

  (define (key-of vals) (map value-key vals))

  ;; Groups of items with equal (key-proc item) lists, in order of first appearance;
  ;; each group keeps the item order.
  (define (partition-rows key-proc items)
    (let ([cells (make-hashtable equal-hash equal?)])   ; key -> (vector members-newest-first)
      (let loop ([items items] [order '()])
        (if (null? items)
            (map (lambda (cell) (reverse (vector-ref cell 0))) (reverse order))
            (let* ([key (key-of (key-proc (car items)))]
                   [cell (hashtable-ref cells key #f)])
              (if cell
                  (begin (vector-set! cell 0 (cons (car items) (vector-ref cell 0)))
                         (loop (cdr items) order))
                  (let ([cell (vector (list (car items)))])
                    (hashtable-set! cells key cell)
                    (loop (cdr items) (cons cell order)))))))))

  ;; The items with a first appearance of each (key-proc item) list.
  (define (distinct-by key-proc items)
    (let ([seen (make-hashtable equal-hash equal?)])
      (filter (lambda (item)
                (let ([key (key-of (key-proc item))])
                  (and (not (hashtable-contains? seen key))
                       (begin (hashtable-set! seen key #t) #t))))
              items))))
