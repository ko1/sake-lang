;;; (engine constraints) -- turning a row of raw values into a stored row, or an
;;; error, under the table's constraints (spec 2.1).
;;;
;;; The checks run in the order the spec fixes, and the first failure is the
;;; error: the rowid's value, NOT NULL, rowid uniqueness, storage conversion, then the other
;;; uniqueness constraints from last to first.  The rowid is the INTEGER PRIMARY KEY column if
;;; the table has one, else the extra last slot of a row (spec 7).
(library (engine constraints)
  (export make-stored-row check-rows-unique)
  (import (rnrs) (engine errors) (engine values) (engine catalog))

  ;; An index equal to the column count means the rowid slot of a table without a key.
  (define (qualified tbl index)
    (string-append (table-name tbl) "."
                   (if (= index (vector-length (table-columns tbl)))
                       "rowid"
                       (column-name (vector-ref (table-columns tbl) index)))))

  (define (fail-unique tbl indexes)
    (raise-sql-error
     (string-append "UNIQUE constraint failed: "
                    (let loop ([is indexes] [acc ""])
                      (cond [(null? is) acc]
                            [(string=? acc "") (loop (cdr is) (qualified tbl (car is)))]
                            [else (loop (cdr is) (string-append acc ", " (qualified tbl (car is))))])))))

  ;; The rowid for a non-NULL raw value (1.5 conversion), or `datatype mismatch`.
  (define (key-value raw)
    (let* ([v (if (string? raw) (or (text->number raw) raw) raw)]
           [n (cond [(integer-value? v) v]
                    [(real-value? v) (real-whole-int64 v)]
                    [else #f])])
      (or n (raise-sql-error "datatype mismatch"))))

  ;; Largest existing rowid (in slot `slot` of each row) + 1, or 1 when there are no rows.
  (define (next-rowid others slot)
    (if (null? others)
        1
        (+ 1 (fold-left (lambda (best row) (max best (vector-ref row slot)))
                        (vector-ref (car others) slot) (cdr others)))))

  ;; Do rows `a` and `b` agree on all of the columns (no NULLs among them)?
  (define (conflicts? row other indexes)
    (for-all (lambda (i)
               (let ([x (vector-ref row i)] [y (vector-ref other i)])
                 (and (not (sql-null? x)) (not (sql-null? y)) (zero? (value-compare x y)))))
             indexes))

  ;; Raises the UNIQUE error if two of the table's rows agree on `indexes` (a new unique index).
  (define (check-rows-unique tbl indexes)
    (let loop ([rows (table-rows tbl)])
      (when (pair? rows)
        (when (exists (lambda (o) (conflicts? (car rows) o indexes)) (cdr rows))
          (fail-unique tbl indexes))
        (loop (cdr rows)))))

  ;; raw: vector of values, one per column, then the rowid's value (NULL: none given; unused
  ;; when the table has an INTEGER PRIMARY KEY, whose column holds it).  others: the table's
  ;; other rows (a list, any order).  auto-key?: a NULL rowid is assigned.  Returns the vector
  ;; to store (columns, then the rowid).
  (define (make-stored-row tbl raw others auto-key?)
    (let* ([cols (table-columns tbl)]
           [n (vector-length cols)]
           [key (table-integer-key tbl)]
           [slot (or key n)]
           [rowid (let ([v (vector-ref raw slot)])
                    (cond [(not (sql-null? v)) (key-value v)]
                          [auto-key? (next-rowid others n)]
                          [else (raise-sql-error "datatype mismatch")]))]
           [row (make-vector (+ n 1) sql-null)])
      ;; NOT NULL, in column order
      (do ([i 0 (+ i 1)]) ((= i n))
        (when (and (not (eqv? i key)) (column-not-null (vector-ref cols i))
                   (sql-null? (vector-ref raw i)))
          (raise-sql-error (string-append "NOT NULL constraint failed: " (qualified tbl i)))))
      (when (exists (lambda (o) (= (vector-ref o n) rowid)) others)
        (fail-unique tbl (list slot)))
      (vector-set! row n rowid)
      (when key (vector-set! row key rowid))
      ;; storage conversion, in column order
      (do ([i 0 (+ i 1)]) ((= i n))
        (unless (eqv? i key)
          (vector-set! row i (store-value tbl (vector-ref cols i) (vector-ref raw i)))))
      (for-each (lambda (indexes)
                  (when (exists (lambda (o) (conflicts? row o indexes)) others)
                    (fail-unique tbl indexes)))
                (reverse (table-uniques tbl)))
      row)))
