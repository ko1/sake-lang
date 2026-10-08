;;; The in-memory database: tables, their columns and their rows.
;;; Tables are found by lowercase name. A row is a vector of values, one per column.
(library (engine catalog)
  (export make-database database-find-table database-add-table! database-remove-table!
          make-column column-name column-lower column-type
          make-table table-name table-columns table-column-count table-find-column
          table-rows table-add-rows!)
  (import (rnrs))

  (define-record-type column (fields name lower type))

  ;; columns: vector of column; rows-rev: rows, newest first.
  (define-record-type table (fields name lower columns (mutable rows-rev)))

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
  (define (table-rows t) (reverse (table-rows-rev t)))

  (define (table-add-rows! t rows)
    (table-rows-rev-set! t (append (reverse rows) (table-rows-rev t)))))
