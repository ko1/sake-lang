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

  ;; A duplicate rowid: named by the INTEGER PRIMARY KEY column if the table has one (7.3).
  (define (fail-rowid tbl)
    (let ([key (table-integer-key tbl)])
      (if key
          (fail-unique tbl (list key))
          (raise-sql-error (string-append "UNIQUE constraint failed: " (table-name tbl) ".rowid")))))

  (define (fail-unique tbl indexes)
    (raise-sql-error
     (string-append "UNIQUE constraint failed: "
                    (let loop ([is indexes] [acc ""])
                      (cond [(null? is) acc]
                            [(string=? acc "") (loop (cdr is) (qualified tbl (car is)))]
                            [else (loop (cdr is) (string-append acc ", " (qualified tbl (car is))))])))))

;; The rowid for a non-NULL raw value (1.5 conversion for an INTEGER column), or `datatype mismatch`.
  (define (key-value raw)
    (let* ([v (if (string? raw) (or (text->number raw) raw) raw)]
           [n (cond [(integer-value? v) v]
                    [(real-value? v) (real-whole-int64 v)]
                    [else #f])])
      (or n (raise-sql-error "datatype mismatch"))))

  ;; Largest existing rowid + 1, or 1 when there are no rows.  The rowid is the row's last slot.
  (define (next-rowid others)
    (if (null? others)
        1
        (+ 1 (fold-left (lambda (best row) (max best (vector-ref row (- (vector-length row) 1))))
                        (vector-ref (car others) (- (vector-length (car others)) 1))
                        (cdr others)))))

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

  ;; raw: vector of n+1 values: one per column, then the rowid as given (NULL: none given).
  ;; others: the table's other rows (a list, any order).  auto-key?: a NULL rowid is numbered
  ;; (a new row) rather than an error (a changed row).  Returns the vector to store: the
  ;; converted columns, then the rowid (7.3).  An INTEGER PRIMARY KEY column is the rowid: its
  ;; raw slot is the one given, and the stored value is in both places.
  (define (make-stored-row tbl raw others auto-key?)
    (let* ([cols (table-columns tbl)]
           [n (vector-length cols)]
           [key (table-integer-key tbl)]
           [given (vector-ref raw (or key n))]
           [rowid (cond [(not (sql-null? given)) (key-value given)]
                        [auto-key? (next-rowid others)]
                        [else (raise-sql-error "datatype mismatch")])]
           [row (make-vector (+ n 1) sql-null)])
      ;; NOT NULL, in column order
      (do ([i 0 (+ i 1)]) ((= i n))
        (when (and (not (eqv? i key)) (column-not-null (vector-ref cols i))
                   (sql-null? (vector-ref raw i)))
          (raise-sql-error (string-append "NOT NULL constraint failed: " (qualified tbl i)))))
      (when (exists (lambda (o) (= (vector-ref o n) rowid)) others)
        (fail-rowid tbl))
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
