;;; Storing one row into a table: type conversion (1.5) and constraints (2.1), shared by INSERT
;;; and UPDATE.
(library (engine constraints)
  (export store-row next-integer-key check-existing-unique convert-value)
  (import (rnrs) (engine errors) (engine catalog) (engine value))

  (define (column-label table idx)
    (string-append (table-name table) "." (column-name (vector-ref (table-columns table) idx))))

  ;; One more than the largest key among rows (a list), or 1.
  (define (next-integer-key table rows)
    (let ([k (table-integer-key table)])
      (+ 1 (fold-left (lambda (m r) (max m (vector-ref r k))) 0 rows))))

  ;; raw: a row vector of unconverted values. other-row?: takes a predicate on rows and says whether
  ;; some row of the table other than this one satisfies it. Returns the converted row, or raises
  ;; the first failure in the order of 2.1.
  (define (store-row table raw other-row?)
    (let* ([cols (table-columns table)]
           [n (vector-length cols)]
           [key (table-integer-key table)]
           [row (make-vector n sql-null)])
      (when key (vector-set! row key (convert-key (vector-ref raw key))))
      (check-not-null table raw key)
      (when key
        (let ([v (vector-ref row key)])
          (when (other-row? (lambda (r) (= 0 (compare-values (vector-ref r key) v))))
            (raise-unique table (list key)))))
      (do ([i 0 (+ i 1)]) ((= i n))
        (unless (eqv? i key) (vector-set! row i (convert-value table i (vector-ref raw i)))))
      (for-each
       (lambda (entry)
         (let ([u (unique-indexes entry)] [colls (unique-collations table entry)])
           (when (and (for-all (lambda (i) (not (sql-null? (vector-ref row i)))) u)
                      (other-row? (lambda (r)
                                    (for-all (lambda (i c) (equal-value? (vector-ref r i) (vector-ref row i) c))
                                             u colls))))
             (raise-unique table u))))
       (reverse (table-uniques table)))
      row))

  ;; An entry of table-uniques is a list whose elements are a column index (compared under the
  ;; column's collation) or (index . collation) (a UNIQUE index column, 7.4).
  (define (unique-indexes entry) (map (lambda (x) (if (pair? x) (car x) x)) entry))
  (define (unique-collations table entry)
    (map (lambda (x) (if (pair? x) (cdr x) (column-collation (vector-ref (table-columns table) x)))) entry))

  ;; A new UNIQUE constraint entry must hold for the rows already in the table (5.7).
  (define (check-existing-unique table entry)
    (let ([seen (make-hashtable equal-hash equal?)]
          [idxs (unique-indexes entry)]
          [colls (unique-collations table entry)])
      (for-each
       (lambda (r)
         (let ([vals (map (lambda (i) (vector-ref r i)) idxs)])
           (unless (exists sql-null? vals)
             (let ([key (map value-key vals colls)])
               (when (hashtable-ref seen key #f) (raise-unique table idxs))
               (hashtable-set! seen key #t)))))
       (table-rows table))))

  (define (equal-value? a b coll)
    (and (not (sql-null? a)) (not (sql-null? b)) (= 0 (compare-values a b coll))))

  (define (convert-key v)
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
