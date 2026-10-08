;;; (engine aggregation) -- evaluating the aggregate calls of one group (spec 3.2, 3.3).
;;;
;;; A group becomes one "group row": a vector holding the values of a representative row of
;;; the group (so bare columns work) followed by one slot per aggregate call, in the order
;;; of the collector's specs.  The expressions compiled against that collector read from it.
(library (engine aggregation)
  (export group-row)
  (import (rnrs) (engine values) (engine ast) (engine expr) (engine aggregates) (engine ordering))

  ;; The rows of the group sorted by the call's own ORDER BY, if it has one.
  (define (rows-in-call-order spec rows)
    (let ([order (aggregate-spec-order spec)])
      (if (null? order)
          rows
          (let ([terms (map car order)])
            (map cdr
                 (list-sort (lambda (a b) (< (compare-keys terms (car a) (car b)) 0))
                            (map (lambda (r) (cons (map (lambda (o) ((cdr o) r)) order) r)) rows)))))))

  (define (compute-call spec rows)
    (let ([args (aggregate-spec-args spec)])
      (aggregate-compute (aggregate-spec-aggregate spec)
                         (aggregate-spec-star spec)
                         (aggregate-spec-distinct spec)
                         (map (lambda (r) (map (lambda (p) (p r)) args))
                              (rows-in-call-order spec rows)))))

  ;; Is the query's only aggregate call a min(x) or max(x)?  Then bare columns come from
  ;; the row that gave the extreme (3.3).
  (define (single-extremum-call specs)
    (and (= (length specs) 1)
         (let ([spec (car specs)])
           (and (not (aggregate-spec-star spec))
                (member (aggregate-name (aggregate-spec-aggregate spec)) '("min" "max"))
                spec))))

  ;; The first row with the extreme non-NULL argument, or the first row if all are NULL.
  (define (extreme-row spec rows)
    (let ([arg (car (aggregate-spec-args spec))]
          [better? (if (string=? (aggregate-name (aggregate-spec-aggregate spec)) "min") negative? positive?)])
      (let loop ([rs rows] [best #f] [best-value sql-null])
        (cond [(null? rs) (or best (car rows))]
              [else (let ([v (arg (car rs))])
                      (if (and (not (sql-null? v))
                               (or (not best) (better? (value-compare v best-value))))
                          (loop (cdr rs) (car rs) v)
                          (loop (cdr rs) best best-value)))]))))

  (define (representative-row specs ncols rows)
    (cond [(null? rows) (make-vector ncols sql-null)]
          [(single-extremum-call specs) => (lambda (spec) (extreme-row spec rows))]
          [else (car rows)]))

  ;; ncols: the number of columns of the rows (0 without a table).
  (define (group-row specs ncols rows)
    (list->vector (append (vector->list (representative-row specs ncols rows))
                          (map (lambda (spec) (compute-call spec rows)) specs)))))
