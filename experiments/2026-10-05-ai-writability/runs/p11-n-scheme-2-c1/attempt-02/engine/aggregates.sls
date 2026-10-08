;;; (engine aggregates) -- the aggregate functions of spec 3.2.
;;;
;;; An aggregate is computed over the rows of one group, each row given as the list of its
;;; evaluated arguments.  To add one, add a line to `aggregate-table`.
(library (engine aggregates)
  (export find-aggregate aggregate-call? aggregate-name aggregate-min-args aggregate-max-args
          aggregate-compute)
  (import (rnrs) (engine errors) (engine values))

  ;; proc takes the argument lists of the rows that count: first argument not NULL, and
  ;; (for DISTINCT) each distinct first argument once; and the collation symbol of the first
  ;; argument (only min and max look at it).
  (define-record-type aggregate (fields name min-args max-args proc))

  ;;; ---- sums (3.2) --------------------------------------------------------------

  ;; A value as the number a sum sees: numeric text is that number, other text is a REAL.
  (define (summand v)
    (if (string? v)
        (or (text->number v) (inexact (text->number-prefix v)))
        v))

  (define (checked-integer-sum ints)
    (let ([s (apply + ints)])
      (when (or (< s int64-min) (> s int64-max)) (raise-sql-error "integer overflow"))
      s))

  ;; Compensated sum: the integers before the first non-integer are summed exactly first.
  (define (compensated-sum nums)
    (let loop ([nums nums] [ints '()])
      (if (integer-value? (car nums))
          (loop (cdr nums) (cons (car nums) ints))
          (let loop2 ([vs nums] [s (inexact (apply + ints))] [c 0.0])
            (if (null? vs)
                (+ s c)
                (let* ([v (inexact (car vs))] [t (+ s v)])
                  (loop2 (cdr vs) t
                         (if (> (abs s) (abs v))
                             (+ c (+ (- s t) v))
                             (+ c (+ (- v t) s))))))))))

  ;; The numbers to sum, or '() when there are none.
  (define (summands rows) (map (lambda (r) (summand (car r))) rows))

  ;; INTEGER sum when every value is an INTEGER, else the compensated REAL sum.
  (define (agg-sum rows)
    (let ([nums (summands rows)])
      (cond [(null? nums) sql-null]
            [(for-all integer-value? nums) (checked-integer-sum nums)]
            [else (compensated-sum nums)])))

  (define (real-sum nums)
    (if (for-all integer-value? nums) (inexact (checked-integer-sum nums)) (compensated-sum nums)))

  (define (agg-total rows)
    (let ([nums (summands rows)]) (if (null? nums) 0.0 (real-sum nums))))

  (define (agg-avg rows)
    (let ([nums (summands rows)])
      (if (null? nums) sql-null (/ (real-sum nums) (inexact (length nums))))))

  ;;; ---- the others -------------------------------------------------------------

  (define (agg-count rows) (length rows))

  ;; The first of the extreme values under the collation; `better?` takes (compare candidate best).
  (define (extremum better?)
    (lambda (rows coll)
      (if (null? rows)
          sql-null
          (fold-left (lambda (best r) (if (better? (value-compare (car r) best coll)) (car r) best))
                     (caar rows) (cdr rows)))))

  ;; An aggregate procedure that ignores the collation.
  (define (plain proc) (lambda (rows coll) (proc rows)))

  ;; Each value after the first is preceded by the separator of its own row.
  (define (agg-group-concat rows)
    (if (null? rows)
        sql-null
        (let ([separator (lambda (r)
                           (cond [(null? (cdr r)) ","]
                                 [(sql-null? (cadr r)) ""]
                                 [else (value->text (cadr r))]))])
          (apply string-append
                 (value->text (caar rows))
                 (map (lambda (r) (string-append (separator r) (value->text (car r)))) (cdr rows))))))

  (define aggregate-table
    (let ([table (make-hashtable string-hash string=?)])
      (for-each (lambda (entry) (hashtable-set! table (car entry) (apply make-aggregate entry)))
                (list (list "count" 1 1 (plain agg-count))
                      (list "sum" 1 1 (plain agg-sum))
                      (list "total" 1 1 (plain agg-total))
                      (list "avg" 1 1 (plain agg-avg))
                      (list "min" 1 1 (extremum negative?))
                      (list "max" 1 1 (extremum positive?))
                      (list "group_concat" 1 2 (plain agg-group-concat))))
      table))

  (define (find-aggregate lname) (hashtable-ref aggregate-table lname #f))

  ;; Is `name(args...)` with this many arguments an aggregate call?  min/max with
  ;; two or more arguments are the scalar functions.
  (define (aggregate-call? lname nargs)
    (and (find-aggregate lname)
         (not (and (member lname '("min" "max")) (>= nargs 2)))
         #t))

  ;; arg-rows: one list of argument values per row (empty lists for count(*)); coll: the
  ;; collation symbol of the first argument.
  (define (aggregate-compute agg star? distinct? arg-rows coll)
    (if star?
        (length arg-rows)
        (let* ([present (filter (lambda (r) (not (sql-null? (car r)))) arg-rows)]
               [counted (if distinct? (distinct-first-arguments present coll) present)])
          ((aggregate-proc agg) counted coll))))

  ;; The rows with a first appearance of each first argument, distinct under the collation.
  (define (distinct-first-arguments rows coll)
    (let ([seen (make-hashtable equal-hash equal?)])
      (filter (lambda (r)
                (let ([key (collate-value (car r) coll)])
                  (and (not (hashtable-contains? seen key))
                       (begin (hashtable-set! seen key #t) #t))))
              rows))))
