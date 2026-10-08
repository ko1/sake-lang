;;; (engine constraints) -- turning a row of raw values into a stored row, or an
;;; error, under the table's constraints (spec 2.1).
;;;
;;; The checks run in the order the spec fixes, and the first failure is the
;;; error: INTEGER PRIMARY KEY value, NOT NULL, key uniqueness, storage
;;; conversion, then the other uniqueness constraints from last to first.
(library (engine constraints)
  (export make-stored-row check-rows-unique)
  (import (rnrs) (engine errors) (engine values) (engine catalog))

  (define (qualified tbl index)
    (string-append (table-name tbl) "." (column-name (vector-ref (table-columns tbl) index))))

  (define (fail-unique tbl indexes)
    (raise-sql-error
     (string-append "UNIQUE constraint failed: "
                    (let loop ([is indexes] [acc ""])
                      (cond [(null? is) acc]
                            [(string=? acc "") (loop (cdr is) (qualified tbl (car is)))]
                            [else (loop (cdr is) (string-append acc ", " (qualified tbl (car is))))])))))

  ;; The INTEGER PRIMARY KEY value for a non-NULL raw value (1.5 conversion), or `datatype mismatch`.
  (define (key-value raw)
    (let* ([v (if (string? raw) (or (text->number raw) raw) raw)]
           [n (cond [(integer-value? v) v]
                    [(real-value? v) (real-whole-int64 v)]
                    [else #f])])
      (or n (raise-sql-error "datatype mismatch"))))

  ;; Largest existing key + 1, or 1 when there are no rows.
  (define (next-key others index)
    (if (null? others)
        1
        (+ 1 (fold-left (lambda (best row) (max best (vector-ref row index)))
                        (vector-ref (car others) index) (cdr others)))))

  ;; Do rows `row` and `other` agree on all of the columns of `entry`, an (indexes . collations)
  ;; pair, each under its collation (no NULLs among them)?
  (define (conflicts? row other entry)
    (for-all (lambda (i collation)
               (let ([x (vector-ref row i)] [y (vector-ref other i)])
                 (and (not (sql-null? x)) (not (sql-null? y)) (zero? (value-compare x y collation)))))
             (car entry) (cdr entry)))

  ;; Raises the UNIQUE error if two of the table's rows agree on `entry` (a new unique index).
  (define (check-rows-unique tbl entry)
    (let loop ([rows (table-rows tbl)])
      (when (pair? rows)
        (when (exists (lambda (o) (conflicts? (car rows) o entry)) (cdr rows))
          (fail-unique tbl (car entry)))
        (loop (cdr rows)))))

  ;; raw: vector of values, one per column.  others: the table's other rows (a
  ;; list, any order).  Returns the vector to store.
  (define (make-stored-row tbl raw others auto-key?)
    (let* ([cols (table-columns tbl)]
           [n (vector-length cols)]
           [key (table-integer-key tbl)]
           [key-v (and key
                       (cond [(not (sql-null? (vector-ref raw key))) (key-value (vector-ref raw key))]
                             [auto-key? (next-key others key)]
                             [else (raise-sql-error "datatype mismatch")]))]
           [row (make-vector n sql-null)])
      ;; NOT NULL, in column order
      (do ([i 0 (+ i 1)]) ((= i n))
        (when (and (not (eqv? i key)) (column-not-null (vector-ref cols i))
                   (sql-null? (vector-ref raw i)))
          (raise-sql-error (string-append "NOT NULL constraint failed: " (qualified tbl i)))))
      (when key
        (when (exists (lambda (o) (= (vector-ref o key) key-v)) others)
          (fail-unique tbl (list key)))
        (vector-set! row key key-v))
      ;; storage conversion, in column order
      (do ([i 0 (+ i 1)]) ((= i n))
        (unless (eqv? i key)
          (vector-set! row i (store-value tbl (vector-ref cols i) (vector-ref raw i)))))
      (for-each (lambda (entry)
                  (when (exists (lambda (o) (conflicts? row o entry)) others)
                    (fail-unique tbl (car entry))))
                (reverse (table-uniques tbl)))
      row)))
