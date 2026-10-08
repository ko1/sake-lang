;;; CREATE / DROP of tables, views and indexes (1.4, 2.1, 5.3, 5.7). Tables and views share one
;;; name space; indexes have their own, but may not take the name of a table or view.
(library (engine ddl)
  (export execute-create-table execute-drop-table execute-create-view execute-drop-view
          execute-create-index execute-drop-index)
  (import (rnrs) (only (chezscheme) iota) (engine errors) (engine ast) (engine catalog)
          (engine constraints) (engine value))

  ;; Whether a new table or view called nm may be created: #t, or #f when IF NOT EXISTS makes the
  ;; statement a no-op. Raises the error for a taken name.
  (define (name-available? db nm if-not-exists)
    (let ([lower (name-lower nm)] [text (name-text nm)])
      (cond
        [(database-find-table db lower)
         (if if-not-exists #f (raise-sql-error (string-append "table " text " already exists")))]
        [(database-find-view db lower)
         (if if-not-exists #f (raise-sql-error (string-append "view " text " already exists")))]
        [(database-find-index db lower)
         (raise-sql-error (string-append "there is already an index named " text))]
        [else #t])))

  (define (execute-create-table db stmt)
    (let ([nm (create-table-name stmt)])
      (when (name-available? db nm (create-table-if-not-exists stmt))
        (database-add-table! db (build-table stmt)))))

  ;; The select is not checked here: its errors belong to the statements that use the view.
  (define (execute-create-view db stmt)
    (let ([nm (create-view-name stmt)])
      (when (name-available? db nm (create-view-if-not-exists stmt))
        (database-add-view! db (make-view (name-text nm) (name-lower nm)
                                          (and (create-view-columns stmt)
                                               (map name-text (create-view-columns stmt)))
                                          (create-view-query stmt))))))

  (define (execute-create-index db stmt)
    (let* ([nm (create-index-name stmt)]
           [tnm (create-index-table stmt)]
           [table (or (database-find-table db (name-lower tnm))
                      (if (database-find-view db (name-lower tnm))
                          (raise-sql-error "views may not be indexed")
                          (raise-sql-error (string-append "no such table: " (name-text tnm)))))])
      (when (or (database-find-table db (name-lower nm)) (database-find-view db (name-lower nm)))
        (raise-sql-error (string-append "there is already a table named " (name-text nm))))
      (cond
        [(database-find-index db (name-lower nm))
         (unless (create-index-if-not-exists stmt)
           (raise-sql-error (string-append "index " (name-text nm) " already exists")))]
        [else
         (let* ([idxs (map (lambda (c) (or (table-find-column table (name-lower c))
                                           (raise-sql-error (string-append "no such column: " (name-text c)))))
                           (create-index-columns stmt))]
                ;; a COLLATE on an index column replaces the column's own collation (7.4)
                [colls (map (lambda (i c)
                              (if c (collation-symbol c) (column-collation-symbol (vector-ref (table-columns table) i))))
                            idxs (create-index-collations stmt))]
                [entry (and (create-index-unique? stmt) (map cons idxs colls))])
           (when entry
             (check-existing-unique table entry)
             (table-set-uniques! table (append (table-uniques table) (list entry))))
           (database-add-index! db (make-index (name-text nm) (name-lower nm) table entry)))])))

  (define (build-table stmt)
    (let* ([nm (create-table-name stmt)]
           [defs (create-table-columns stmt)]
           [lowers (column-lowers defs)]
           [constraints (declared-constraints defs (create-table-constraints stmt) lowers)]
           [pk-columns (apply append (map cdr (filter (lambda (c) (eq? (car c) 'primary-key)) constraints)))]
           [cols (build-columns defs pk-columns)]
           [integer-key (find-integer-key cols constraints)])
      (make-table (name-text nm) (name-lower nm) cols
                  (map (lambda (c)
                         (map (lambda (i) (cons i (column-collation-symbol (vector-ref cols i)))) (cdr c)))
                       (filter (lambda (c) (not (and integer-key (eq? (car c) 'primary-key)
                                                     (equal? (cdr c) (list integer-key)))))
                               constraints))
                  integer-key)))

  ;; The collation (a symbol) of a table column.
  (define (column-collation-symbol col) (cdr (column-collation col)))

  (define (column-lowers defs)
    (let loop ([defs defs] [seen '()])
      (if (null? defs)
          (reverse seen)
          (let ([nm (column-def-name (car defs))])
            (when (member (name-lower nm) seen)
              (raise-sql-error (string-append "duplicate column name: " (name-text nm))))
            (loop (cdr defs) (cons (name-lower nm) seen))))))

  (define (index-of lower lowers)
    (let loop ([l lowers] [i 0])
      (cond [(null? l) #f] [(string=? (car l) lower) i] [else (loop (cdr l) (+ i 1))])))

  (define (name->index nm lowers)
    (or (index-of (name-lower nm) lowers)
        (raise-sql-error (string-append "no such column: " (name-text nm)))))

  ;; The PRIMARY KEY / UNIQUE constraints as (kind . column-indexes), in declaration order:
  ;; column constraints in column order, then table constraints.
  (define (declared-constraints defs table-constraints lowers)
    (append
     (apply append
            (map (lambda (d i)
                   (append (if (column-def-primary-key? d) (list (list 'primary-key i)) '())
                           (if (column-def-unique? d) (list (list 'unique i)) '())))
                 defs (iota (length defs))))
     (map (lambda (tc)
            (cons (table-constraint-kind tc)
                  (map (lambda (nm) (name->index nm lowers)) (table-constraint-columns tc))))
          table-constraints)))

  ;; indexes of PRIMARY KEY columns get NOT NULL.
  (define (build-columns defs pk-columns)
    (list->vector
     (map (lambda (d i)
            (make-column (name-text (column-def-name d)) (name-lower (column-def-name d))
                         (column-def-type d)
                         (or (column-def-not-null? d) (and (memv i pk-columns) #t))
                         (column-def-default d)
                         (cons 'implicit (declared-collation (column-def-collation d)))))
          defs (iota (length defs)))))

  ;; A PRIMARY KEY of one INTEGER column is the row key (2.1).
  (define (find-integer-key cols constraints)
    (let loop ([cs constraints])
      (cond [(null? cs) #f]
            [(and (eq? (caar cs) 'primary-key) (= (length (cdar cs)) 1)
                  (eq? (column-type (vector-ref cols (cadar cs))) 'integer))
             (cadar cs)]
            [else (loop (cdr cs))])))

  (define (execute-drop-table db stmt)
    (let* ([nm (drop-table-name stmt)] [lower (name-lower nm)]
           [table (database-find-table db lower)] [view (database-find-view db lower)])
      (cond
        [table (database-remove-indexes-of db table) (database-remove-table! db lower)]
        [view (raise-sql-error (string-append "use DROP VIEW to delete view " (view-name view)))]
        [(drop-table-if-exists stmt) #f]
        [else (raise-sql-error (string-append "no such table: " (name-text nm)))])))

  (define (execute-drop-view db stmt)
    (let* ([nm (drop-view-name stmt)] [lower (name-lower nm)]
           [table (database-find-table db lower)])
      (cond
        [(database-find-view db lower) (database-remove-view! db lower)]
        [table (raise-sql-error (string-append "use DROP TABLE to delete table " (table-name table)))]
        [(drop-view-if-exists stmt) #f]
        [else (raise-sql-error (string-append "no such view: " (name-text nm)))])))

  (define (execute-drop-index db stmt)
    (let ([nm (drop-index-name stmt)])
      (cond
        [(database-find-index db (name-lower nm)) (database-remove-index! db (name-lower nm))]
        [(drop-index-if-exists stmt) #f]
        [else (raise-sql-error (string-append "no such index: " (name-text nm)))]))))
