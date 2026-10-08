;;; (engine ddl) -- CREATE / DROP of tables and views (spec 1.4, 2.1, 5.3).
(library (engine ddl)
  (export exec-create-table exec-drop-table exec-create-view exec-drop-view name-free?)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine catalog)
          (only (chezscheme) iota))

  (define (name-index names lname)
    (let loop ([ns names] [i 0])
      (cond [(null? ns) #f]
            [(string=? (ascii-downcase (car ns)) lname) i]
            [else (loop (cdr ns) (+ i 1))])))

  (define (check-no-duplicates names)
    (let loop ([ns names] [seen '()])
      (unless (null? ns)
        (let ([lname (ascii-downcase (car ns))])
          (when (member lname seen)
            (raise-sql-error (string-append "duplicate column name: " (car ns))))
          (loop (cdr ns) (cons lname seen))))))

  ;; Indexes of the columns a table constraint names.
  (define (constraint-indexes names constraint)
    (map (lambda (c)
           (or (name-index names (ascii-downcase c))
               (raise-sql-error (string-append "no such column: " c))))
         (table-constraint-columns constraint)))

  ;; Constraints as (kind . indexes) in declaration order: column constraints in
  ;; column order, then the table constraints.
  (define (declared-constraints defs names constraints)
    (append
     (apply append
            (map (lambda (def i)
                   (append (if (column-def-primary def) (list (cons 'primary (list i))) '())
                           (if (column-def-unique def) (list (cons 'unique (list i))) '())))
                 defs (iota (length defs))))
     (map (lambda (c) (cons (table-constraint-kind c) (constraint-indexes names c))) constraints)))

  (define (filter-map f items) (filter values (map f items)))

  (define (integer-primary-key? defs declared)
    (let ([primary (find (lambda (d) (eq? (car d) 'primary)) declared)])
      (and primary (= (length (cdr primary)) 1)
           (eq? (column-def-type (list-ref defs (cadr primary))) 'integer)
           (cadr primary))))

  ;; The collation (symbol) a column definition declares; binary if none (7.2).
  (define (def-collation def)
    (if (column-def-collation def) (lookup-collation (column-def-collation def)) 'binary))

  (define (build-table name defs constraints)
    (let* ([collations (map def-collation defs)]   ; first: an unknown name fails before anything else
           [names (map column-def-name defs)]
           [checked (check-no-duplicates names)]
           [declared (declared-constraints defs names constraints)]
           [key (integer-primary-key? defs declared)]
           [uniques (filter-map (lambda (d)
                                  (and (not (and key (eq? (car d) 'primary) (equal? (cdr d) (list key))))
                                       (cons (cdr d) (map (lambda (i) (list-ref collations i)) (cdr d)))))
                                declared)]
           [primary-columns (apply append (filter-map (lambda (d) (and (eq? (car d) 'primary) (cdr d)))
                                                      declared))]
           [columns (map (lambda (def i)
                           (make-column (column-def-name def) (ascii-downcase (column-def-name def))
                                        (column-def-type def)
                                        (or (column-def-not-null def) (and (memv i primary-columns) #t))
                                        (column-def-default def)
                                        (list-ref collations i)))
                         defs (iota (length defs)))])
      (make-table name columns key uniques)))

  ;;; ---- names: tables and views share one name space (5.3), indexes have their own (5.7) ----

  ;; Can a new table or view be called `name`?  #t if so; #f if the statement is IF NOT EXISTS
  ;; and a table or view has the name (nothing to do); otherwise the error.
  (define (name-free? db name if-not-exists)
    (let ([lname (ascii-downcase name)])
      (cond [(database-find-table db lname)
             (if if-not-exists #f (raise-sql-error (string-append "table " name " already exists")))]
            [(database-find-view db lname)
             (if if-not-exists #f (raise-sql-error (string-append "view " name " already exists")))]
            [(database-find-index db lname)
             (raise-sql-error (string-append "there is already an index named " name))]
            [else #t])))

  (define (exec-create-table db stmt)
    (let ([name (create-table-stmt-name stmt)])
      (when (name-free? db name (create-table-stmt-if-not-exists stmt))
        (database-add-table! db (build-table name (create-table-stmt-columns stmt)
                                             (create-table-stmt-constraints stmt))))))

  (define (exec-drop-table db stmt)
    (let* ([name (drop-table-stmt-name stmt)] [lname (ascii-downcase name)]
           [tbl (database-find-table db lname)]
           [view (database-find-view db lname)])
      (cond [tbl (for-each (lambda (ix) (database-remove-index! db (ascii-downcase (index-def-name ix))))
                           (database-indexes-of db tbl))
                 (database-remove-table! db lname)]
            [view (raise-sql-error (string-append "use DROP VIEW to delete view " (view-name view)))]
            [(drop-table-stmt-if-exists stmt) #f]
            [else (raise-sql-error (string-append "no such table: " name))])))

  ;;; ---- views (5.3) ----------------------------------------------------------

  ;; The select is not checked here: each use of the view plans it.
  (define (exec-create-view db stmt)
    (let ([name (create-view-stmt-name stmt)])
      (when (name-free? db name (create-view-stmt-if-not-exists stmt))
        (database-add-view! db (make-view name (create-view-stmt-columns stmt)
                                          (create-view-stmt-select stmt))))))

  (define (exec-drop-view db stmt)
    (let* ([name (drop-view-stmt-name stmt)] [lname (ascii-downcase name)]
           [tbl (database-find-table db lname)])
      (cond [(database-find-view db lname) (database-remove-view! db lname)]
            [tbl (raise-sql-error (string-append "use DROP TABLE to delete table " (table-name tbl)))]
            [(drop-view-stmt-if-exists stmt) #f]
            [else (raise-sql-error (string-append "no such view: " name))]))))
