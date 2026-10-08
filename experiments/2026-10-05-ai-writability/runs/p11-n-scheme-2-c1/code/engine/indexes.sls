;;; (engine indexes) -- CREATE INDEX and DROP INDEX (spec 5.7).
;;;
;;; An index changes no result, so a plain index is only a name that belongs to a table.  A
;;; UNIQUE index is also a uniqueness constraint on the table, added after those it already
;;; has (constraints are checked last-declared first, so it is checked first).
(library (engine indexes)
  (export exec-create-index exec-drop-index)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine catalog) (engine constraints))

  ;; The (indexes . collations) entry (see (engine catalog)) for the index columns `names`;
  ;; `collation-names` holds each one's COLLATE name as written or #f (then the column's own).
  (define (index-entry tbl names collation-names)
    (let loop ([names names] [cnames collation-names] [indexes '()] [collations '()])
      (if (null? names)
          (cons (reverse indexes) (reverse collations))
          (let* ([c (car names)]
                 [i (or (table-find-column tbl (ascii-downcase c))
                        (raise-sql-error (string-append "no such column: " c)))]
                 [collation (if (car cnames)
                                (lookup-collation (car cnames))
                                (column-collation (vector-ref (table-columns tbl) i)))])
            (loop (cdr names) (cdr cnames) (cons i indexes) (cons collation collations))))))

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
                [entry (index-entry tbl (create-index-stmt-columns stmt)
                                    (create-index-stmt-collations stmt))]
                [unique? (create-index-stmt-unique stmt)])
           (when unique?
             (check-rows-unique tbl entry)
             (table-set-uniques! tbl (append (table-uniques tbl) (list entry))))
           (database-add-index! db (make-index-def name tbl (and unique? entry))))])))

  (define (exec-drop-index db stmt)
    (let* ([name (drop-index-stmt-name stmt)] [lname (ascii-downcase name)]
           [ix (database-find-index db lname)])
      (cond [ix (let ([entry (index-def-unique ix)] [tbl (index-def-table ix)])
                  (when entry
                    (table-set-uniques! tbl (remp (lambda (u) (eq? u entry)) (table-uniques tbl))))
                  (database-remove-index! db lname))]
            [(drop-index-stmt-if-exists stmt) #f]
            [else (raise-sql-error (string-append "no such index: " name))]))))
