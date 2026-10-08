;;; INSERT ... VALUES and INSERT ... SELECT (1.6, 2.1, 5.4). All rows are checked before any is
;;; stored, so a failing statement stores nothing.
(library (engine insert)
  (export execute-insert)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine scope) (engine expr)
          (engine constraints) (engine select))

  (define (execute-insert db stmt)
    (let ([source (insert-source stmt)])
      (if (query? source)
          (insert-from-query db stmt source)
          (insert-from-values db stmt source))))

  ;; The table inserted into; a view cannot be (5.3).
  (define (target-table db tname)
    (cond [(database-find-table db (name-lower tname)) => values]
          [(database-find-view db (name-lower tname))
           => (lambda (v) (raise-sql-error (string-append "cannot modify " (view-name v) " because it is a view")))]
          [else (raise-sql-error (string-append "no such table: " (name-text tname)))]))

  (define (insert-from-values db stmt rows)
    (let ([tname (insert-table stmt)])
      (unless (for-all (lambda (r) (= (length r) (length (car rows)))) rows)
        (raise-sql-error "all VALUES must have the same number of terms"))
      (let* ([table (target-table db tname)]
             [targets (target-indexes table tname (insert-columns stmt))]
             [m (length (car rows))])
        (check-counts table tname (insert-columns stmt) targets m)
        (let* ([no-row (make-scope db '() #f)]
               [compiled (map (lambda (row) (map (lambda (e) (compile-expr e no-row)) row)) rows)])
          (store-all! table targets compiled)))))

  ;; The select is fully computed before any row is stored.
  (define (insert-from-query db stmt query)
    (let* ([tname (insert-table stmt)]
           [table (target-table db tname)]
           [targets (target-indexes table tname (insert-columns stmt))])
      (let-values ([(cols run) (prepare-select db query #f)])
        (check-counts table tname (insert-columns stmt) targets (vector-length cols))
        (store-all! table targets
                    (map (lambda (row) (map (lambda (v) (lambda (no-row) v)) row)) (run))))))

  ;; Builds and checks the rows one at a time, each against the table plus the earlier new rows.
  (define (store-all! table targets compiled)
    (let ([existing (table-rows table)])
      (let loop ([compiled compiled] [pool existing] [fresh '()])
        (if (null? compiled)
            (table-set-rows! table (append existing (reverse fresh)))
            (let* ([raw (raw-row table targets (car compiled) pool)]
                   [row (store-row table raw (lambda (pred) (exists pred pool)))])
              (loop (cdr compiled) (cons row pool) (cons row fresh)))))))

  ;; The unconverted row (columns, then the rowid slot): given values, else DEFAULT, else NULL; the
  ;; rowid is assigned if absent (7.3).
  (define (raw-row table targets fs pool)
    (let* ([n (table-column-count table)]
           [raw (make-vector (+ n 1) sql-null)]
           [key (table-integer-key table)]
           [rid (table-rowid-target table)])
      (do ([i 0 (+ i 1)]) ((= i n))
        (let ([d (column-default (vector-ref (table-columns table) i))])
          (when (and d (not (eqv? i key))) (vector-set! raw i (car d)))))
      (for-each (lambda (idx f) (vector-set! raw idx (f (vector)))) targets fs)
      (when (sql-null? (vector-ref raw rid))
        (vector-set! raw rid (next-rowid table pool)))
      raw))

  ;; Row indexes receiving the values, in value order; a rowid name that is not a real column
  ;; stands for the rowid (7.3).
  (define (target-indexes table tname columns)
    (if columns
        (map (lambda (nm)
               (or (table-find-column table (name-lower nm))
                   (and (rowid-name? (name-lower nm)) (table-rowid-target table))
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
