;;; The in-memory database: tables, their columns, constraints and rows.
;;; Tables are found by lowercase name. A row is a vector of values, one per column.
(library (engine catalog)
  (export make-database database-find-table database-add-table! database-remove-table!
          make-column column-name column-lower column-type column-not-null? column-default
          make-table table-name table-lower table-columns table-column-count table-find-column
          table-uniques table-integer-key table-rows table-set-rows!)
  (import (rnrs))

  ;; not-null?: NOT NULL (or part of a PRIMARY KEY); default: #f or (list value).
  (define-record-type column (fields name lower type not-null? default))

  ;; columns: vector of column. uniques: list of column-index lists, in declaration order (2.1);
  ;; it holds UNIQUE and non-integer PRIMARY KEY constraints. integer-key: index of the
  ;; INTEGER PRIMARY KEY column, or #f.
  (define-record-type table
    (fields name lower columns uniques integer-key (mutable rows-in-order))
    (protocol (lambda (new)
                (lambda (name lower columns uniques integer-key)
                  (new name lower columns uniques integer-key '())))))

  (define-record-type database
    (fields tables)
    (protocol (lambda (new) (lambda () (new (make-hashtable string-hash string=?))))))

  (define (database-find-table db lower) (hashtable-ref (database-tables db) lower #f))
  (define (database-add-table! db table)
    (hashtable-set! (database-tables db) (table-lower table) table))
  (define (database-remove-table! db lower) (hashtable-delete! (database-tables db) lower))

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

  (define (table-set-rows! t rows) (table-rows-in-order-set! t rows)))
