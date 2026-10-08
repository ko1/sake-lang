;;; (engine catalog) -- the database: tables, their columns and rows, and the
;;; rule for storing a value into a column (spec 1.4, 1.5).
;;;
;;; A row is a vector of values, one per column.  Table lookup is by
;;; lower-cased name; the name as written in CREATE TABLE is kept for messages.
(library (engine catalog)
  (export make-column column-name column-lname column-type
          make-table table-name table-columns table-rows table-add-rows! table-find-column
          make-database database-find-table database-add-table! database-remove-table!
          store-value)
  (import (rnrs) (engine errors) (engine values))

  ;; type: one of the symbols integer real text
  (define-record-type column (fields name lname type))

  (define-record-type table
    (fields name columns (mutable rows-reversed))
    (protocol (lambda (new) (lambda (name columns) (new name (list->vector columns) '())))))

  (define (table-rows t) (reverse (table-rows-reversed t)))

  ;; Append already-validated rows, in order.
  (define (table-add-rows! t rows)
    (table-rows-reversed-set! t (append (reverse rows) (table-rows-reversed t))))

  ;; Index of the column with this lower-cased name, or #f.
  (define (table-find-column t lname)
    (let ([cols (table-columns t)])
      (let loop ([i 0])
        (cond [(= i (vector-length cols)) #f]
              [(string=? (column-lname (vector-ref cols i)) lname) i]
              [else (loop (+ i 1))]))))

  (define-record-type database
    (fields tables)
    (protocol (lambda (new) (lambda () (new (make-hashtable string-hash string=?))))))

  (define (database-find-table db lname) (hashtable-ref (database-tables db) lname #f))
  (define (database-add-table! db t)
    (hashtable-set! (database-tables db) (ascii-downcase (table-name t)) t))
  (define (database-remove-table! db lname) (hashtable-delete! (database-tables db) lname))

  ;;; ---- storing a value (1.5) -------------------------------------------

  (define (type-word type)
    (case type [(integer) "INTEGER"] [(real) "REAL"] [else "TEXT"]))

  ;; The value converted to the column's type; raises the spec's error if it cannot be.
  (define (store-value tbl col v)
    (define (reject value-type)
      (raise-sql-error (string-append "cannot store " value-type " value in "
                                      (type-word (column-type col)) " column "
                                      (table-name tbl) "." (column-name col))))
    (let* ([ctype (column-type col)]
           [v (if (and (string? v) (not (eq? ctype 'text))) (or (text->number v) v) v)])
      (cond
        [(sql-null? v) v]
        [else
         (case ctype
           [(integer) (cond [(string? v) (reject "TEXT")]
                            [(integer-value? v) v]
                            [else (or (real-whole-int64 v) (reject "REAL"))])]
           [(real) (if (string? v) (reject "TEXT") (inexact v))]
           [else (value->text v)])]))))
