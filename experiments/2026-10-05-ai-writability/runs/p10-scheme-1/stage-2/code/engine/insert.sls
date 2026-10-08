;;; INSERT (1.6, 2.1). All rows are checked before any is stored, so a failing statement stores
;;; nothing.
(library (engine insert)
  (export execute-insert)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine expr)
          (engine constraints))

  (define (execute-insert db stmt)
    (let* ([tname (insert-table stmt)]
           [rows (insert-rows stmt)])
      (unless (for-all (lambda (r) (= (length r) (length (car rows)))) rows)
        (raise-sql-error "all VALUES must have the same number of terms"))
      (let ([table (database-find-table db (name-lower tname))])
        (unless table (raise-sql-error (string-append "no such table: " (name-text tname))))
        (let* ([targets (target-indexes table tname (insert-columns stmt))]
               [m (length (car rows))])
          (check-counts table tname (insert-columns stmt) targets m)
          (let ([compiled (map (lambda (row) (map (lambda (e) (compile-expr e no-row-scope)) row)) rows)])
            (store-all! table targets compiled))))))

  ;; Builds and checks the rows one at a time, each against the table plus the earlier new rows.
  (define (store-all! table targets compiled)
    (let ([existing (table-rows table)])
      (let loop ([compiled compiled] [pool existing] [fresh '()])
        (if (null? compiled)
            (table-set-rows! table (append existing (reverse fresh)))
            (let* ([raw (raw-row table targets (car compiled) pool)]
                   [row (store-row table raw (lambda (pred) (exists pred pool)))])
              (loop (cdr compiled) (cons row pool) (cons row fresh)))))))

  ;; The unconverted row: given values, else DEFAULT, else NULL; the row key is assigned if absent.
  (define (raw-row table targets fs pool)
    (let ([raw (make-vector (table-column-count table) sql-null)]
          [key (table-integer-key table)])
      (do ([i 0 (+ i 1)]) ((= i (vector-length raw)))
        (let ([d (column-default (vector-ref (table-columns table) i))])
          (when (and d (not (eqv? i key))) (vector-set! raw i (car d)))))
      (for-each (lambda (idx f) (vector-set! raw idx (f (vector)))) targets fs)
      (when (and key (sql-null? (vector-ref raw key)))
        (vector-set! raw key (next-integer-key table pool)))
      raw))

  ;; Column indexes receiving the values, in value order.
  (define (target-indexes table tname columns)
    (if columns
        (map (lambda (nm)
               (or (table-find-column table (name-lower nm))
                   (raise-sql-error (string-append "table " (name-text tname)
                                                   " has no column named " (name-text nm)))))
             columns)
        (let loop ([i (- (table-column-count table) 1)] [acc '()])
          (if (< i 0) acc (loop (- i 1) (cons i acc))))))

  (define (check-counts table tname columns targets m)
    (unless (= m (length targets))
      (raise-sql-error
       (if columns
           (string-append (number->string m) " values for " (number->string (length targets)) " columns")
           (string-append "table " (name-text tname) " has " (number->string (table-column-count table))
                          " columns but " (number->string m) " values were supplied"))))))
