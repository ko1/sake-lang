;;; (engine catalog) -- the database: tables, their columns and rows, and the
;;; rule for storing a value into a column (spec 1.4, 1.5).
;;;
;;; Constraints (spec 2.1) are kept on the table: `integer-key` is the index of
;;; the INTEGER PRIMARY KEY column or #f, `uniques` a list of column-index lists
;;; (one per UNIQUE / non-integer PRIMARY KEY, in declaration order).  They are
;;; enforced by (engine constraints), not here.
;;;
;;; The database also holds views (named selects), indexes (names, each owned by a table; a
;;; UNIQUE index also lives on its table as a uniqueness constraint) and, while a statement
;;; with a WITH clause is planned, its common table expressions.  Tables, views and ctes are
;;; looked up by lower-cased name.  Transactions are snapshots of all of this.
;;;
;;; A row is a vector of values, one per column.  Table lookup is by
;;; lower-cased name; the name as written in CREATE TABLE is kept for messages.
(library (engine catalog)
  (export make-column column-name column-lname column-type column-not-null column-default
          make-table table-name table-columns table-rows table-set-rows! table-add-rows!
          table-integer-key table-uniques table-find-column
          table-set-name! table-set-columns! table-set-uniques!
          make-view view-name view-columns view-select
          make-index-def index-def-name index-def-table index-def-unique
          make-database database-find-table database-add-table! database-remove-table!
          database-tables-list
          database-find-view database-add-view! database-remove-view!
          database-find-index database-add-index! database-remove-index! database-indexes-of
          make-cte-entry cte-entry-name cte-entry-columns cte-entry-plan
          database-find-cte database-with-ctes database-without-ctes
          database-snapshot database-restore! database-transaction database-transaction-set!
          store-value)
  (import (rnrs) (engine errors) (engine values))

  ;; type: one of the symbols integer real text; default: a value (NULL if none)
  (define-record-type column (fields name lname type not-null default))

  (define-record-type table
    (fields (mutable name) (mutable columns) integer-key (mutable uniques) (mutable rows-reversed))
    (protocol (lambda (new)
                (lambda (name columns integer-key uniques)
                  (new name (list->vector columns) integer-key uniques '())))))

  (define (table-rows t) (reverse (table-rows-reversed t)))
  (define (table-set-rows! t rows) (table-rows-reversed-set! t (reverse rows)))

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

;; name: as written in CREATE VIEW; columns: list of names or #f; select: a select or compound
  (define-record-type view (fields name columns select))

  ;; table: the table object; unique: the column-index list this index adds to the table's
  ;; `uniques` (the very same list object), or #f for a plain index.
  (define-record-type index-def (fields name table unique))

  ;; A common table expression as the planner sees it: columns: names or #f;
  ;; plan: thunk -> a plan (engine plan), made anew for each use.
  (define-record-type cte-entry (fields name columns plan))

  ;; transaction: #f or the snapshot taken by BEGIN.
  (define-record-type (database make-database-record database?)
    (fields tables views indexes ctes (mutable transaction)))

  (define (make-database)
    (make-database-record (make-hashtable string-hash string=?) (make-hashtable string-hash string=?)
                          (make-hashtable string-hash string=?) '() #f))

  (define (database-find-table db lname) (hashtable-ref (database-tables db) lname #f))
  (define (database-add-table! db t)
    (hashtable-set! (database-tables db) (ascii-downcase (table-name t)) t))
  (define (database-remove-table! db lname) (hashtable-delete! (database-tables db) lname))
  (define (database-tables-list db) (map cdr (hashtable->alist (database-tables db))))

  (define (database-find-view db lname) (hashtable-ref (database-views db) lname #f))
  (define (database-add-view! db v)
    (hashtable-set! (database-views db) (ascii-downcase (view-name v)) v))
  (define (database-remove-view! db lname) (hashtable-delete! (database-views db) lname))

  (define (database-find-index db lname) (hashtable-ref (database-indexes db) lname #f))
  (define (database-add-index! db ix)
    (hashtable-set! (database-indexes db) (ascii-downcase (index-def-name ix)) ix))
  (define (database-remove-index! db lname) (hashtable-delete! (database-indexes db) lname))
  (define (database-indexes-of db tbl)
    (filter (lambda (ix) (eq? (index-def-table ix) tbl))
            (map cdr (hashtable->alist (database-indexes db)))))

  ;;; ---- common table expressions ------------------------------------------

  (define (database-find-cte db lname) (assoc lname (database-ctes db)))

  ;; A view of the same database where `entries` (cte-entry list, later ones hide earlier) are
  ;; also visible.  The tables are shared, so it is only for planning.
  (define (database-with-ctes db entries)
    (make-database-record (database-tables db) (database-views db) (database-indexes db)
                          (append (map (lambda (e) (cons (ascii-downcase (cte-entry-name e)) e))
                                       (reverse entries))
                                  (database-ctes db))
                          #f))

  (define (database-without-ctes db)
    (make-database-record (database-tables db) (database-views db) (database-indexes db) '() #f))

  ;;; ---- snapshots, for transactions --------------------------------------

  (define (hashtable->alist ht)
    (let-values ([(keys vals) (hashtable-entries ht)])
      (map cons (vector->list keys) (vector->list vals))))

  (define (restore-hashtable! ht entries)
    (hashtable-clear! ht)
    (for-each (lambda (e) (hashtable-set! ht (car e) (cdr e))) entries))

  ;; Everything a statement can change.  Row vectors are never modified in place, so sharing
  ;; them is safe; the mutable table fields are saved by value.
  (define (database-snapshot db)
    (list (map (lambda (e)
                 (let ([t (cdr e)])
                   (list (car e) t (table-name t) (table-columns t) (table-uniques t)
                         (table-rows-reversed t))))
               (hashtable->alist (database-tables db)))
          (hashtable->alist (database-views db))
          (hashtable->alist (database-indexes db))))

  (define (database-restore! db snapshot)
    (restore-hashtable! (database-tables db)
                        (map (lambda (e)
                               (let ([t (cadr e)])
                                 (table-name-set! t (caddr e))
                                 (table-columns-set! t (cadddr e))
                                 (table-uniques-set! t (list-ref e 4))
                                 (table-rows-reversed-set! t (list-ref e 5))
                                 (cons (car e) t)))
                             (car snapshot)))
    (restore-hashtable! (database-views db) (cadr snapshot))
    (restore-hashtable! (database-indexes db) (caddr snapshot)))

  (define (table-set-name! t name) (table-name-set! t name))
  (define (table-set-columns! t columns) (table-columns-set! t columns))
  (define (table-set-uniques! t uniques) (table-uniques-set! t uniques))

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
