;;; (engine ddl) -- CREATE TABLE and DROP TABLE (spec 1.4, 2.1).
(library (engine ddl)
  (export exec-create-table exec-drop-table)
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

  (define (build-table name defs constraints)
    (let* ([names (map column-def-name defs)]
           [checked (check-no-duplicates names)]
           [declared (declared-constraints defs names constraints)]
           [key (integer-primary-key? defs declared)]
           [uniques (filter-map (lambda (d)
                                  (and (not (and key (eq? (car d) 'primary) (equal? (cdr d) (list key))))
                                       (cdr d)))
                                declared)]
           [primary-columns (apply append (filter-map (lambda (d) (and (eq? (car d) 'primary) (cdr d)))
                                                      declared))]
           [columns (map (lambda (def i)
                           (make-column (column-def-name def) (ascii-downcase (column-def-name def))
                                        (column-def-type def)
                                        (or (column-def-not-null def) (and (memv i primary-columns) #t))
                                        (column-def-default def)))
                         defs (iota (length defs)))])
      (make-table name columns key uniques)))

  (define (exec-create-table db stmt)
    (let* ([name (create-table-stmt-name stmt)]
           [exists? (database-find-table db (ascii-downcase name))])
      (cond
        [(and exists? (create-table-stmt-if-not-exists stmt)) #f]
        [exists? (raise-sql-error (string-append "table " name " already exists"))]
        [else (database-add-table! db (build-table name (create-table-stmt-columns stmt)
                                                   (create-table-stmt-constraints stmt)))])))

  (define (exec-drop-table db stmt)
    (let* ([name (drop-table-stmt-name stmt)] [lname (ascii-downcase name)])
      (cond [(database-find-table db lname) (database-remove-table! db lname)]
            [(drop-table-stmt-if-exists stmt) #f]
            [else (raise-sql-error (string-append "no such table: " name))]))))
