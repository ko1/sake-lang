;;; (engine alter) -- ALTER TABLE: ADD COLUMN, RENAME TO, RENAME COLUMN (spec 5.6).
;;;
;;; Each change builds the table's new columns and rows first and installs them last, and
;;; never modifies a column vector or row in place (a transaction's snapshot shares them).
(library (engine alter)
  (export exec-alter-add-column exec-alter-rename-table exec-alter-rename-column)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine catalog))

  (define (lookup-table db name)
    (or (database-find-table db (ascii-downcase name))
        (raise-sql-error (string-append "no such table: " name))))

  (define (vector-snoc v x) (list->vector (append (vector->list v) (list x))))

  (define (exec-alter-add-column db stmt)
    (let* ([tbl (lookup-table db (alter-add-column-stmt-table stmt))]
           [def (alter-add-column-stmt-column stmt)]
           [name (column-def-name def)]
           [collation (if (column-def-collation def) (collation-named (column-def-collation def)) 'binary)])
      (when (table-find-column tbl (ascii-downcase name))
        (raise-sql-error (string-append "duplicate column name: " name)))
      (when (column-def-primary def) (raise-sql-error "Cannot add a PRIMARY KEY column"))
      (when (column-def-unique def) (raise-sql-error "Cannot add a UNIQUE column"))
      (when (and (column-def-not-null def) (sql-null? (column-def-default def)) (pair? (table-rows tbl)))
        (raise-sql-error "Cannot add a NOT NULL column with default value NULL"))
      (let* ([column (make-column name (ascii-downcase name) (column-def-type def)
                                  (column-def-not-null def) (column-def-default def) collation)]
             [value (store-value tbl column (column-def-default def))]
             [rows (map (lambda (row) (vector-snoc row value)) (table-rows tbl))])
        (table-set-columns! tbl (vector-snoc (table-columns tbl) column))
        (table-set-rows! tbl rows))))

  (define (exec-alter-rename-table db stmt)
    (let* ([tbl (lookup-table db (alter-rename-table-stmt-table stmt))]
           [new-name (alter-rename-table-stmt-new-name stmt)]
           [new-lname (ascii-downcase new-name)])
      (when (or (database-find-table db new-lname) (database-find-view db new-lname)
                (database-find-index db new-lname))
        (raise-sql-error (string-append "there is already another table or index with this name: "
                                        new-name)))
      (database-remove-table! db (ascii-downcase (table-name tbl)))
      (table-set-name! tbl new-name)
      (database-add-table! db tbl)))

  (define (exec-alter-rename-column db stmt)
    (let* ([tbl (lookup-table db (alter-rename-column-stmt-table stmt))]
           [written (alter-rename-column-stmt-column stmt)]
           [i (or (table-find-column tbl (ascii-downcase written))
                  (raise-sql-error (string-append "no such column: \"" written "\"")))]
           [new-name (alter-rename-column-stmt-new-name stmt)]
           [old (vector-ref (table-columns tbl) i)]
           [columns (vector-map (lambda (c) c) (table-columns tbl))])
      (vector-set! columns i (make-column new-name (ascii-downcase new-name) (column-type old)
                                          (column-not-null old) (column-default old)
                                          (column-collation old)))
      (table-set-columns! tbl columns))))
