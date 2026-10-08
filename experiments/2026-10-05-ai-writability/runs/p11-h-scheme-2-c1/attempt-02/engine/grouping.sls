;;; (engine grouping) -- equality of values for GROUP BY and DISTINCT (spec 1.9: 1 = 1.0, NULLs equal),
;;; TEXT values being equal under a collation (spec 7.4).
;;;
;;; Everywhere below `colls` is a list of collations (binary, nocase, rtrim), one per value of a
;;; key; #f stands for all binary.
(library (engine grouping)
  (export partition-rows distinct-by make-row-set row-set-add! row-set-contains?)
  (import (rnrs) (engine values))

  ;; A value that is `equal?` exactly when the SQL values are equal under `coll`.
  (define (value-key v coll)
    (cond [(real-value? v) (or (real-whole-int64 v) v)]
          [(string? v) (collate-text coll v)]
          [else v]))

  (define (key-of vals colls)
    (let loop ([vals vals] [colls colls])
      (if (null? vals)
          '()
          (cons (value-key (car vals) (if colls (car colls) 'binary))
                (loop (cdr vals) (and colls (cdr colls)))))))

  ;; Groups of items with equal (key-proc item) lists, in order of first appearance;
  ;; each group keeps the item order.
  (define (partition-rows key-proc items colls)
    (let ([cells (make-hashtable equal-hash equal?)])   ; key -> (vector members-newest-first)
      (let loop ([items items] [order '()])
        (if (null? items)
            (map (lambda (cell) (reverse (vector-ref cell 0))) (reverse order))
            (let* ([key (key-of (key-proc (car items)) colls)]
                   [cell (hashtable-ref cells key #f)])
              (if cell
                  (begin (vector-set! cell 0 (cons (car items) (vector-ref cell 0)))
                         (loop (cdr items) order))
                  (let ([cell (vector (list (car items)))])
                    (hashtable-set! cells key cell)
                    (loop (cdr items) (cons cell order)))))))))

  ;; The items with a first appearance of each (key-proc item) list.
  (define (distinct-by key-proc items colls)
    (let ([seen (make-hashtable equal-hash equal?)])
      (filter (lambda (item)
                (let ([key (key-of (key-proc item) colls)])
                  (and (not (hashtable-contains? seen key))
                       (begin (hashtable-set! seen key #t) #t))))
              items)))

  ;; A set of result rows (vectors) under the same equality, column k compared under the k-th of colls.
  (define-record-type (row-set make-row-set-record row-set?) (fields colls table))
  (define (make-row-set colls) (make-row-set-record colls (make-hashtable equal-hash equal?)))
  (define (row-set-key set row) (key-of (vector->list row) (row-set-colls set)))
  (define (row-set-contains? set row) (hashtable-contains? (row-set-table set) (row-set-key set row)))
  ;; Adds the row; #t if it was not in the set yet.
  (define (row-set-add! set row)
    (let ([key (row-set-key set row)])
      (and (not (hashtable-contains? (row-set-table set) key))
           (begin (hashtable-set! (row-set-table set) key #t) #t)))))
