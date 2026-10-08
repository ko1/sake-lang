;;; CREATE TABLE and DROP TABLE (1.4).
(library (engine ddl)
  (export execute-create-table execute-drop-table)
  (import (rnrs) (engine errors) (engine ast) (engine catalog))

  (define (execute-create-table db stmt)
    (let* ([nm (create-table-name stmt)]
           [exists (database-find-table db (name-lower nm))])
      (cond
        [exists
         (unless (create-table-if-not-exists stmt)
           (raise-sql-error (string-append "table " (name-text nm) " already exists")))]
        [else
         (let ([cols (build-columns (create-table-columns stmt))])
           (database-add-table! db (make-table (name-text nm) (name-lower nm) cols '())))])))

  ;; The column vector; the second occurrence of a name is a "duplicate column name" error.
  (define (build-columns defs)
    (let loop ([defs defs] [seen '()] [acc '()])
      (if (null? defs)
          (list->vector (reverse acc))
          (let* ([d (car defs)] [nm (column-def-name d)])
            (when (member (name-lower nm) seen)
              (raise-sql-error (string-append "duplicate column name: " (name-text nm))))
            (loop (cdr defs)
                  (cons (name-lower nm) seen)
                  (cons (make-column (name-text nm) (name-lower nm) (column-def-type d)) acc))))))

  (define (execute-drop-table db stmt)
    (let ([nm (drop-table-name stmt)])
      (cond
        [(database-find-table db (name-lower nm)) (database-remove-table! db (name-lower nm))]
        [(drop-table-if-exists stmt) #f]
        [else (raise-sql-error (string-append "no such table: " (name-text nm)))]))))
