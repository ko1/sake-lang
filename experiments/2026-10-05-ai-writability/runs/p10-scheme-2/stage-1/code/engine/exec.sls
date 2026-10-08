;;; (engine exec) -- running statements against a database, and whole scripts.
(library (engine exec)
  (export run-script)
  (import (rnrs) (engine errors) (engine values) (engine lexer) (engine parser)
          (engine ast) (engine catalog) (engine expr) (engine select)
          (only (chezscheme) iota))

  ;;; ---- CREATE / DROP --------------------------------------------------------------

  (define (exec-create-table db stmt)
    (let* ([name (create-table-stmt-name stmt)]
           [exists? (database-find-table db (ascii-downcase name))])
      (cond
        [(and exists? (create-table-stmt-if-not-exists stmt)) #f]
        [exists? (raise-sql-error (string-append "table " name " already exists"))]
        [else
         (let loop ([defs (create-table-stmt-columns stmt)] [seen '()] [cols '()])
           (cond
             [(null? defs)
              (database-add-table! db (make-table name (reverse cols)))]
             [else
              (let ([lname (ascii-downcase (caar defs))])
                (when (member lname seen)
                  (raise-sql-error (string-append "duplicate column name: " (caar defs))))
                (loop (cdr defs) (cons lname seen)
                      (cons (make-column (caar defs) lname (cdar defs)) cols)))]))])))

  (define (exec-drop-table db stmt)
    (let* ([name (drop-table-stmt-name stmt)] [lname (ascii-downcase name)])
      (cond [(database-find-table db lname) (database-remove-table! db lname)]
            [(drop-table-stmt-if-exists stmt) #f]
            [else (raise-sql-error (string-append "no such table: " name))])))

  ;;; ---- INSERT -----------------------------------------------------------------------

  (define (lookup-table db name)
    (or (database-find-table db (ascii-downcase name))
        (raise-sql-error (string-append "no such table: " name))))

  ;; For each listed column name its index in the table (error if absent).
  (define (insert-target-indexes tbl written-table columns)
    (if columns
        (map (lambda (c)
               (or (table-find-column tbl (ascii-downcase c))
                   (raise-sql-error (string-append "table " written-table " has no column named " c))))
             columns)
        (iota (vector-length (table-columns tbl)))))

  (define (exec-insert db stmt)
    (let* ([written (insert-stmt-table stmt)]
           [rows (insert-stmt-rows stmt)]
           [width (length (car rows))])
      (unless (for-all (lambda (r) (= (length r) width)) rows)
        (raise-sql-error "all VALUES must have the same number of terms"))
      (let* ([tbl (lookup-table db written)]
             [cols (table-columns tbl)]
             [ncols (vector-length cols)]
             [targets (insert-target-indexes tbl written (insert-stmt-columns stmt))]
             [no-scope (make-scope #f '())])
        (unless (= width (length targets))
          (raise-sql-error
           (if (insert-stmt-columns stmt)
               (string-append (number->string width) " values for " (number->string (length targets)) " columns")
               (string-append "table " written " has " (number->string ncols) " columns but "
                              (number->string width) " values were supplied"))))
        (let ([new-rows
               (map (lambda (exprs)
                      (let ([row (make-vector ncols sql-null)])
                        (for-each (lambda (expr index)
                                    (let ([v ((cexpr-proc (compile-expr expr no-scope)) (vector))])
                                      (vector-set! row index (store-value tbl (vector-ref cols index) v))))
                                  exprs targets)
                        row))
                    rows)])
          (table-add-rows! tbl new-rows)))))

  ;;; ---- dispatch and scripts ---------------------------------------------------------

  (define (print-rows rows out)
    (for-each (lambda (row)
                (let loop ([vals (vector->list row)] [first? #t])
                  (unless (null? vals)
                    (unless first? (put-char out #\|))
                    (put-string out (value->display (car vals)))
                    (loop (cdr vals) #f)))
                (put-char out #\newline))
              rows))

  (define (execute db stmt out)
    (cond [(select-stmt? stmt) (print-rows (run-select db stmt) out)]
          [(insert-stmt? stmt) (exec-insert db stmt)]
          [(create-table-stmt? stmt) (exec-create-table db stmt)]
          [(drop-table-stmt? stmt) (exec-drop-table db stmt)]))

  (define (report-error out message)
    (put-string out "Error: ") (put-string out message) (put-char out #\newline))

  (define (run-statement db text out)
    (guard (e [(sql-error? e) (report-error out (sql-error-message e))]
              [(error? e) (report-error out (condition-message-text e))])
      (let ([stmt (parse-statement (tokenize text))])
        (when stmt (execute db stmt out)))))

  ;; Internal failures (bugs) still keep the script going.
  (define (condition-message-text e)
    (if (message-condition? e) (condition-message e) "internal error"))

  ;; Run every statement of `text` in a fresh database, writing to the textual port `out`.
  (define (run-script text out)
    (let ([db (make-database)])
      (for-each (lambda (statement-text) (run-statement db statement-text out))
                (split-statements text)))))
