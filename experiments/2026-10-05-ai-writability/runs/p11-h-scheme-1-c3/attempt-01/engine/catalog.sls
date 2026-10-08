;;; The in-memory database: tables, views, indexes, and the transaction snapshot.
;;; Tables, views and indexes are found by lowercase name. A row is a vector of values, one per column.
(library (engine catalog)
  (export make-database database-find-table database-add-table! database-remove-table!
          database-find-view database-add-view! database-remove-view!
          database-find-index database-add-index! database-remove-index! database-remove-indexes-of
          database-tables-list
          make-column column-name column-lower column-type column-not-null? column-default
          make-table table-name table-lower table-columns table-column-count table-find-column
          table-uniques table-integer-key table-rows table-set-rows! table-set-columns!
          table-set-uniques! table-rename! rowid-name? table-rowid-target
          make-view view-name view-lower view-columns view-query
          make-index index-name index-lower index-table index-constraint
          database-in-transaction? database-begin! database-commit! database-rollback!)
  (import (rnrs))

  ;; not-null?: NOT NULL (or part of a PRIMARY KEY); default: #f or (list value).
  (define-record-type column (fields name lower type not-null? default))

  ;; Every stored row is a vector of the column values followed by one more element: its rowid (7.1).
  ;; columns: vector of column. uniques: list of column-index lists, in declaration order (2.1);
  ;; it holds UNIQUE and non-integer PRIMARY KEY constraints and UNIQUE indexes. integer-key:
  ;; index of the INTEGER PRIMARY KEY column, or #f.
  (define-record-type table
    (fields (mutable name) (mutable lower) (mutable columns) (mutable uniques) integer-key
            (mutable rows-in-order))
    (protocol (lambda (new)
                (lambda (name lower columns uniques integer-key)
                  (new name lower columns uniques integer-key '())))))

  ;; columns: #f or a list of column names; query: the select (an engine ast query), unchecked.
  (define-record-type view (fields name lower columns query))

  ;; constraint: the entry of table-uniques that a UNIQUE index put there (compared with eq?), or #f.
  (define-record-type index (fields name lower table constraint))

  ;; saved: #f, or the snapshot taken by BEGIN.
  (define-record-type database
    (fields tables views indexes (mutable saved))
    (protocol (lambda (new)
                (lambda ()
                  (new (make-hashtable string-hash string=?) (make-hashtable string-hash string=?)
                       (make-hashtable string-hash string=?) #f)))))

  (define (database-find-table db lower) (hashtable-ref (database-tables db) lower #f))
  (define (database-add-table! db table)
    (hashtable-set! (database-tables db) (table-lower table) table))
  (define (database-remove-table! db lower) (hashtable-delete! (database-tables db) lower))
  (define (hashtable-value-list h)
    (let-values ([(ks vs) (hashtable-entries h)]) (vector->list vs)))
  (define (database-tables-list db) (hashtable-value-list (database-tables db)))

  (define (database-find-view db lower) (hashtable-ref (database-views db) lower #f))
  (define (database-add-view! db view) (hashtable-set! (database-views db) (view-lower view) view))
  (define (database-remove-view! db lower) (hashtable-delete! (database-views db) lower))

  (define (database-find-index db lower) (hashtable-ref (database-indexes db) lower #f))
  (define (database-add-index! db index) (hashtable-set! (database-indexes db) (index-lower index) index))

  ;; Removes the index from the table's constraints as well.
  (define (database-remove-index! db lower)
    (let ([ix (database-find-index db lower)])
      (when ix
        (let ([c (index-constraint ix)] [t (index-table ix)])
          (when c (table-set-uniques! t (remp (lambda (u) (eq? u c)) (table-uniques t)))))
        (hashtable-delete! (database-indexes db) lower))))

  ;; Dropping a table drops its indexes.
  (define (database-remove-indexes-of db table)
    (for-each (lambda (ix)
                (when (eq? (index-table ix) table) (hashtable-delete! (database-indexes db) (index-lower ix))))
              (hashtable-value-list (database-indexes db))))

  ;; Whether the lowercase name is one of the three rowid names (7.1).
  (define (rowid-name? lower) (and (member lower '("rowid" "_rowid_" "oid")) #t))

  ;; Row index that stores into the rowid (7.3): the INTEGER PRIMARY KEY column, else the extra slot.
  (define (table-rowid-target t) (or (table-integer-key t) (table-column-count t)))

  (define (table-column-count t) (vector-length (table-columns t)))

  ;; Index of the column with this lowercase name, or #f.
  (define (table-find-column t lower)
    (let ([cols (table-columns t)])
      (let loop ([i 0])
        (cond [(= i (vector-length cols)) #f]
              [(string=? (column-lower (vector-ref cols i)) lower) i]
              [else (loop (+ i 1))]))))

  ;; Rows in insertion order.
  (define (table-rows t) (table-rows-in-order t))

  (define (table-set-rows! t rows) (table-rows-in-order-set! t rows))
  (define (table-set-columns! t cols) (table-columns-set! t cols))
  (define (table-set-uniques! t uniques) (table-uniques-set! t uniques))

  ;; Renames the table object; the caller re-files it in the database.
  (define (table-rename! t name lower) (table-name-set! t name) (table-lower-set! t lower))

  ;; ---- transactions (5.5) ----
  ;; BEGIN saves the namespaces and each table's mutable state; ROLLBACK puts them back. Rows are
  ;; never changed in place, so saving the lists is enough.

  (define (database-in-transaction? db) (and (database-saved db) #t))

  (define (hashtable-pairs h)
    (let-values ([(ks vs) (hashtable-entries h)]) (map cons (vector->list ks) (vector->list vs))))

  (define (restore-hashtable! h pairs)
    (hashtable-clear! h)
    (for-each (lambda (p) (hashtable-set! h (car p) (cdr p))) pairs))

  (define (database-begin! db)
    (database-saved-set!
     db
     (list (hashtable-pairs (database-tables db)) (hashtable-pairs (database-views db))
           (hashtable-pairs (database-indexes db))
           (map (lambda (t)
                  (list t (table-name t) (table-lower t) (table-columns t) (table-uniques t) (table-rows t)))
                (database-tables-list db)))))

  (define (database-commit! db) (database-saved-set! db #f))

  (define (database-rollback! db)
    (let ([s (database-saved db)])
      (restore-hashtable! (database-tables db) (car s))
      (restore-hashtable! (database-views db) (cadr s))
      (restore-hashtable! (database-indexes db) (caddr s))
      (for-each (lambda (e)
                  (let ([t (car e)])
                    (table-rename! t (cadr e) (caddr e))
                    (table-set-columns! t (cadddr e))
                    (table-set-uniques! t (list-ref e 4))
                    (table-set-rows! t (list-ref e 5))))
                (cadddr s))
      (database-saved-set! db #f))))
