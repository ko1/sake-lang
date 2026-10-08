;;; INSERT (1.6). All rows are built before any is stored, so a failing statement stores nothing.
(library (engine insert)
  (export execute-insert)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine expr))

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
            (table-add-rows!
             table
             (map (lambda (fs) (build-row table targets fs)) compiled)))))))

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
                          " columns but " (number->string m) " values were supplied")))))

  (define (build-row table targets compiled)
    (let ([row (make-vector (table-column-count table) sql-null)]
          [no-row (vector)])
      (for-each
       (lambda (idx f)
         (let ([col (vector-ref (table-columns table) idx)])
           (let-values ([(stored rejected) (store-convert (column-type col) (f no-row))])
             (when rejected
               (raise-sql-error
                (string-append "cannot store " rejected " value in "
                               (string-upcase (symbol->string (column-type col))) " column "
                               (table-name table) "." (column-name col))))
             (vector-set! row idx stored))))
       targets compiled)
      row)))
