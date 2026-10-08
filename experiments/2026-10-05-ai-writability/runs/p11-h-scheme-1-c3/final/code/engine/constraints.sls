;;; Storing one row into a table: type conversion (1.5) and constraints (2.1), shared by INSERT
;;; and UPDATE.
(library (engine constraints)
  (export store-row next-rowid check-existing-unique convert-value)
  (import (rnrs) (engine errors) (engine catalog) (engine value))

  ;; idx = the column count names the rowid slot of a table without an INTEGER PRIMARY KEY (7.3).
  (define (column-label table idx)
    (string-append (table-name table) "."
                   (if (= idx (table-column-count table))
                       "rowid"
                       (column-name (vector-ref (table-columns table) idx)))))

  ;; One more than the largest rowid among rows (a list of stored rows), or 1 (7.3).
  (define (next-rowid table rows)
    (let ([n (table-column-count table)])
      (if (null? rows)
          1
          (+ 1 (fold-left (lambda (m r) (max m (vector-ref r n))) (vector-ref (car rows) n) (cdr rows))))))

  ;; raw: a vector of unconverted values, one per column and then the rowid (7.1); the rowid value
  ;; is in the INTEGER PRIMARY KEY column if the table has one. other-row?: takes a predicate on rows and says whether
  ;; some row of the table other than this one satisfies it. Returns the converted row (with its
  ;; rowid), or raises the first failure in the order of 2.1 and 7.3.
  (define (store-row table raw other-row?)
    (let* ([cols (table-columns table)]
           [n (vector-length cols)]
           [key (table-integer-key table)]
           [rid (or key n)]
           [row (make-vector (+ n 1) sql-null)])
      (vector-set! row rid (convert-rowid (vector-ref raw rid)))
      (check-not-null table raw key)
      (let ([v (vector-ref row rid)])
        (when (other-row? (lambda (r) (= v (vector-ref r rid))))
          (raise-unique table (list rid))))
      (do ([i 0 (+ i 1)]) ((= i n))
        (unless (eqv? i key) (vector-set! row i (convert-value table i (vector-ref raw i)))))
      (for-each
       (lambda (u)
         (when (and (for-all (lambda (i) (not (sql-null? (vector-ref row i)))) u)
                    (other-row? (lambda (r) (for-all (lambda (i) (equal-value? (vector-ref r i) (vector-ref row i))) u))))
           (raise-unique table u)))
       (reverse (table-uniques table)))
      (vector-set! row n (vector-ref row rid))
      row))

  ;; A new UNIQUE constraint on columns idxs must hold for the rows already in the table (5.7).
  (define (check-existing-unique table idxs)
    (let ([seen (make-hashtable equal-hash equal?)])
      (for-each
       (lambda (r)
         (let ([vals (map (lambda (i) (vector-ref r i)) idxs)])
           (unless (exists sql-null? vals)
             (let ([key (map value-key vals)])
               (when (hashtable-ref seen key #f) (raise-unique table idxs))
               (hashtable-set! seen key #t)))))
       (table-rows table))))

  (define (equal-value? a b)
    (and (not (sql-null? a)) (not (sql-null? b)) (= 0 (compare-values a b))))

  (define (convert-rowid v)
    (let-values ([(stored rejected) (store-convert 'integer v)])
      (if (or rejected (sql-null? stored)) (raise-sql-error "datatype mismatch") stored)))

  (define (check-not-null table raw key)
    (let ([cols (table-columns table)])
      (do ([i 0 (+ i 1)]) ((= i (vector-length cols)))
        (when (and (not (eqv? i key)) (column-not-null? (vector-ref cols i)) (sql-null? (vector-ref raw i)))
          (raise-sql-error (string-append "NOT NULL constraint failed: " (column-label table i)))))))

  (define (convert-value table idx v)
    (let* ([col (vector-ref (table-columns table) idx)])
      (let-values ([(stored rejected) (store-convert (column-type col) v)])
        (when rejected
          (raise-sql-error
           (string-append "cannot store " rejected " value in "
                          (string-upcase (symbol->string (column-type col))) " column "
                          (column-label table idx))))
        stored)))

  (define (raise-unique table idxs)
    (raise-sql-error
     (string-append "UNIQUE constraint failed: "
                    (let loop ([l idxs] [acc ""])
                      (cond [(null? l) acc]
                            [(string=? acc "") (loop (cdr l) (column-label table (car l)))]
                            [else (loop (cdr l) (string-append acc ", " (column-label table (car l))))]))))))
