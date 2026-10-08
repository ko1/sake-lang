;;; (engine grouping) -- equality of values for GROUP BY and DISTINCT (spec 1.9: 1 = 1.0, NULLs equal).
;;; Text equal under a collation (7.1) is made the same by the caller (collate-value) before it
;;; gets here, except in a row set, which is given the collations of its columns.
(library (engine grouping)
  (export partition-rows distinct-by make-row-set row-set-add! row-set-contains?)
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
              items)))

  ;; A set of result rows (vectors) under the same equality, text under the given collations
  ;; (a list of symbols, one per column).
  (define-record-type (row-set new-row-set row-set?) (fields table collations))
  (define (make-row-set collations) (new-row-set (make-hashtable equal-hash equal?) collations))
  (define (row-set-key set row)
    (key-of (map collate-value (vector->list row) (row-set-collations set))))
  (define (row-set-contains? set row) (hashtable-contains? (row-set-table set) (row-set-key set row)))
  ;; Adds the row; #t if it was not in the set yet.
  (define (row-set-add! set row)
    (let ([key (row-set-key set row)] [table (row-set-table set)])
      (and (not (hashtable-contains? table key))
           (begin (hashtable-set! table key #t) #t)))))
