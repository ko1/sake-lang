;;; (engine indexes) -- CREATE INDEX and DROP INDEX (spec 5.7).
;;;
;;; An index changes no result, so a plain index is only a name that belongs to a table.  A
;;; UNIQUE index is also a uniqueness constraint on the table, added after those it already
;;; has (constraints are checked last-declared first, so it is checked first).
(library (engine indexes)
  (export exec-create-index exec-drop-index)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine catalog) (engine constraints))

  (define (column-indexes tbl names)
    (map (lambda (c)
           (or (table-find-column tbl (ascii-downcase c))
               (raise-sql-error (string-append "no such column: " c))))
         names))

  (define (exec-create-index db stmt)
    (let* ([name (create-index-stmt-name stmt)] [lname (ascii-downcase name)])
      (cond
        [(database-find-index db lname)
         (unless (create-index-stmt-if-not-exists stmt)
           (raise-sql-error (string-append "index " name " already exists")))]
        [(or (database-find-table db lname) (database-find-view db lname))
         (raise-sql-error (string-append "there is already a table named " name))]
        [else
         (let* ([written (create-index-stmt-table stmt)]
                [tbl (or (database-find-table db (ascii-downcase written))
                         (raise-sql-error (string-append "no such table: " written)))]
                [indexes (column-indexes tbl (create-index-stmt-columns stmt))]
                [unique? (create-index-stmt-unique stmt)])
           (when unique?
             (check-rows-unique tbl indexes)
             (table-set-uniques! tbl (append (table-uniques tbl) (list indexes))))
           (database-add-index! db (make-index-def name tbl (and unique? indexes))))])))

  (define (exec-drop-index db stmt)
    (let* ([name (drop-index-stmt-name stmt)] [lname (ascii-downcase name)]
           [ix (database-find-index db lname)])
      (cond [ix (let ([indexes (index-def-unique ix)] [tbl (index-def-table ix)])
                  (when indexes
                    (table-set-uniques! tbl (remp (lambda (u) (eq? u indexes)) (table-uniques tbl))))
                  (database-remove-index! db lname))]
            [(drop-index-stmt-if-exists stmt) #f]
            [else (raise-sql-error (string-append "no such index: " name))]))))
