;;; (engine dml) -- INSERT, UPDATE and DELETE (spec 1.6, 2.2).
;;;
;;; Each statement builds the table's new row list and installs it only when
;;; every row has passed (engine constraints), so a failure changes nothing.
(library (engine dml)
  (export exec-insert exec-update exec-delete)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine catalog)
          (engine sources) (engine expr) (engine constraints) (only (chezscheme) iota vector-copy))

  (define (lookup-table db name)
    (or (database-find-table db (ascii-downcase name))
        (raise-sql-error (string-append "no such table: " name))))

  ;; The table being changed is a source named by its table name, for subqueries (spec 4.2).
  (define (target-scope db tbl)
    (make-scope (make-level db (sources-add '() (table-name tbl) (table-columns tbl) '()) #f) '()))

  (define (compile-proc expr scope) (cexpr-proc (compile-expr expr scope)))

  ;;; ---- INSERT -----------------------------------------------------------------

  ;; For each listed column name its index in the table (error if absent).
  (define (insert-target-indexes tbl written-table columns)
    (if columns
        (map (lambda (c)
               (or (table-find-column tbl (ascii-downcase c))
                   (raise-sql-error (string-append "table " written-table " has no column named " c))))
             columns)
        (iota (vector-length (table-columns tbl)))))

  ;; A raw row: unlisted columns take their DEFAULT (NULL when none; the
  ;; INTEGER PRIMARY KEY ignores its DEFAULT).
  (define (raw-insert-row tbl targets procs)
    (let* ([cols (table-columns tbl)]
           [raw (make-vector (vector-length cols) sql-null)])
      (do ([i 0 (+ i 1)]) ((= i (vector-length cols)))
        (vector-set! raw i (column-default (vector-ref cols i))))
      (let ([key (table-integer-key tbl)])
        (when key (vector-set! raw key sql-null)))
      (for-each (lambda (index proc) (vector-set! raw index (proc (vector)))) targets procs)
      raw))

  (define (exec-insert db stmt)
    (let* ([written (insert-stmt-table stmt)]
           [rows (insert-stmt-rows stmt)]
           [width (length (car rows))])
      (unless (for-all (lambda (r) (= (length r) width)) rows)
        (raise-sql-error "all VALUES must have the same number of terms"))
      (let* ([tbl (lookup-table db written)]
             [ncols (vector-length (table-columns tbl))]
             [targets (insert-target-indexes tbl written (insert-stmt-columns stmt))]
             [no-scope (make-scope (make-level db '() #f) '())])
        (unless (= width (length targets))
          (raise-sql-error
           (if (insert-stmt-columns stmt)
               (string-append (number->string width) " values for " (number->string (length targets)) " columns")
               (string-append "table " written " has " (number->string ncols) " columns but "
                              (number->string width) " values were supplied"))))
        (let ([row-procs (map (lambda (exprs) (map (lambda (e) (compile-proc e no-scope)) exprs)) rows)])
          ;; `others` = every row stored so far, existing ones included (any order).
          (let loop ([row-procs row-procs] [others (table-rows tbl)] [added '()])
            (if (null? row-procs)
                (table-add-rows! tbl (reverse added))
                (let* ([raw (raw-insert-row tbl targets (car row-procs))]
                       [row (make-stored-row tbl raw others #t)])
                  (loop (cdr row-procs) (cons row others) (cons row added)))))))))

  ;;; ---- UPDATE -----------------------------------------------------------------

  ;; The rows of vector `rows` except the one at index `skip`, as a list.
  (define (rows-except rows skip)
    (let loop ([i (- (vector-length rows) 1)] [acc '()])
      (cond [(< i 0) acc]
            [(= i skip) (loop (- i 1) acc)]
            [else (loop (- i 1) (cons (vector-ref rows i) acc))])))

  (define (exec-update db stmt)
    (let* ([tbl (lookup-table db (update-stmt-table stmt))]
           [scope (target-scope db tbl)]
           [targets (map (lambda (a)
                           (or (table-find-column tbl (ascii-downcase (car a)))
                               (raise-sql-error (string-append "no such column: " (car a)))))
                         (update-stmt-assignments stmt))]
           [procs (map (lambda (a) (compile-proc (cdr a) scope)) (update-stmt-assignments stmt))]
           [where (and (update-stmt-where stmt) (compile-proc (update-stmt-where stmt) scope))]
           [rows (list->vector (table-rows tbl))])
      (do ([i 0 (+ i 1)]) ((= i (vector-length rows)))
        (let ([old (vector-ref rows i)])
          (when (or (not where) (eq? (truth (where old)) #t))
            (let ([raw (vector-copy old)])
              ;; in order, so a column named twice keeps the last assignment
              (for-each (lambda (index proc) (vector-set! raw index (proc old))) targets procs)
              (vector-set! rows i (make-stored-row tbl raw (rows-except rows i) #f))))))
      (table-set-rows! tbl (vector->list rows))))

  ;;; ---- DELETE -----------------------------------------------------------------

  (define (exec-delete db stmt)
    (let* ([tbl (lookup-table db (delete-stmt-table stmt))]
           [where (and (delete-stmt-where stmt)
                       (compile-proc (delete-stmt-where stmt) (target-scope db tbl)))])
      (table-set-rows! tbl (if where
                               (filter (lambda (row) (not (eq? (truth (where row)) #t))) (table-rows tbl))
                               '())))))
