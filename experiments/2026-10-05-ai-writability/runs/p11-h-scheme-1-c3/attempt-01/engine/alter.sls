;;; ALTER TABLE (5.6): add a column, rename the table, rename a column. Each statement checks
;;; everything before changing anything. Constraints refer to columns by index and indexes to their
;;; table object, so they follow a rename without being touched.
(library (engine alter)
  (export execute-alter-add-column execute-alter-rename-table execute-alter-rename-column)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine constraints))

  (define (find-table db nm)
    (or (database-find-table db (name-lower nm))
        (raise-sql-error (string-append "no such table: " (name-text nm)))))

  (define (execute-alter-add-column db stmt)
    (let* ([table (find-table db (alter-add-column-table stmt))]
           [def (alter-add-column-def stmt)]
           [nm (column-def-name def)]
           [default (column-def-default def)]
           [non-null-default? (and default (not (sql-null? (car default))))])
      (when (table-find-column table (name-lower nm))
        (raise-sql-error (string-append "duplicate column name: " (name-text nm))))
      (when (column-def-primary-key? def) (raise-sql-error "Cannot add a PRIMARY KEY column"))
      (when (column-def-unique? def) (raise-sql-error "Cannot add a UNIQUE column"))
      (when (and (column-def-not-null? def) (not non-null-default?) (pair? (table-rows table)))
        (raise-sql-error "Cannot add a NOT NULL column with default value NULL"))
      (let* ([col (make-column (name-text nm) (name-lower nm) (column-def-type def)
                               (column-def-not-null? def) default)]
             [old (table-columns table)]
             [n (vector-length old)]
             [new (make-vector (+ n 1) col)])
        (do ([i 0 (+ i 1)]) ((= i n)) (vector-set! new i (vector-ref old i)))
        ;; the existing rows get the default converted as a stored value (1.5)
        (let ([fill (convert-value (make-table (table-name table) (table-lower table) new '() #f)
                                   n (if default (car default) sql-null))])
          (table-set-rows! table (map (lambda (r) (extend-row r fill)) (table-rows table)))
          (table-set-columns! table new)))))

  ;; The new column goes before the rowid, which stays the last element of the row.
  (define (extend-row r v)
    (let* ([n (vector-length r)] [new (make-vector (+ n 1) v)])
      (do ([i 0 (+ i 1)]) ((= i (- n 1)))
        (vector-set! new i (vector-ref r i)))
      (vector-set! new n (vector-ref r (- n 1)))
      new))

  (define (execute-alter-rename-table db stmt)
    (let* ([table (find-table db (alter-rename-table-table stmt))]
           [nm (alter-rename-table-new-name stmt)] [lower (name-lower nm)])
      (when (or (database-find-table db lower) (database-find-view db lower) (database-find-index db lower))
        (raise-sql-error
         (string-append "there is already another table or index with this name: " (name-text nm))))
      (database-remove-table! db (table-lower table))
      (table-rename! table (name-text nm) lower)
      (database-add-table! db table)))

  (define (execute-alter-rename-column db stmt)
    (let* ([table (find-table db (alter-rename-column-table stmt))]
           [old (alter-rename-column-old stmt)] [nm (alter-rename-column-new stmt)]
           [i (or (table-find-column table (name-lower old))
                  (raise-sql-error (string-append "no such column: \"" (name-text old) "\"")))]
           [cols (table-columns table)]
           [c (vector-ref cols i)]
           [new (make-vector (vector-length cols))])
      (do ([j 0 (+ j 1)]) ((= j (vector-length cols)))
        (vector-set! new j (vector-ref cols j)))
      (vector-set! new i (make-column (name-text nm) (name-lower nm) (column-type c)
                                      (column-not-null? c) (column-default c)))
      (table-set-columns! table new))))
