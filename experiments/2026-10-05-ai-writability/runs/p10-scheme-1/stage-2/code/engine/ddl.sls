;;; CREATE TABLE and DROP TABLE (1.4, 2.1).
(library (engine ddl)
  (export execute-create-table execute-drop-table)
  (import (rnrs) (only (chezscheme) iota) (engine errors) (engine ast) (engine catalog))

  (define (execute-create-table db stmt)
    (let* ([nm (create-table-name stmt)]
           [exists (database-find-table db (name-lower nm))])
      (cond
        [exists
         (unless (create-table-if-not-exists stmt)
           (raise-sql-error (string-append "table " (name-text nm) " already exists")))]
        [else (database-add-table! db (build-table stmt))])))

  (define (build-table stmt)
    (let* ([nm (create-table-name stmt)]
           [defs (create-table-columns stmt)]
           [lowers (column-lowers defs)]
           [constraints (declared-constraints defs (create-table-constraints stmt) lowers)]
           [pk-columns (apply append (map cdr (filter (lambda (c) (eq? (car c) 'primary-key)) constraints)))]
           [cols (build-columns defs pk-columns)]
           [integer-key (find-integer-key cols constraints)])
      (make-table (name-text nm) (name-lower nm) cols
                  (map cdr (filter (lambda (c) (not (and integer-key (eq? (car c) 'primary-key)
                                                         (equal? (cdr c) (list integer-key)))))
                                   constraints))
                  integer-key)))

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
                         (column-def-default d)))
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
    (let ([nm (drop-table-name stmt)])
      (cond
        [(database-find-table db (name-lower nm)) (database-remove-table! db (name-lower nm))]
        [(drop-table-if-exists stmt) #f]
        [else (raise-sql-error (string-append "no such table: " (name-text nm)))]))))
