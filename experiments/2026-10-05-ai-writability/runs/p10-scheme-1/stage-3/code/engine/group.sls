;;; Grouping (3.3) and DISTINCT (3.4): partitioning rows, and folding each group through the
;;; query's aggregates into one evaluation row.
(library (engine group)
  (export group-evaluation-rows distinct-results)
  (import (rnrs) (engine value) (engine aggregate))

  ;; The evaluation rows of an aggregate query. rows: the source rows after WHERE; key-procs:
  ;; GROUP BY terms (row -> value); collector: the aggregates of the query; width: columns of the
  ;; source table. Each group gives one vector: a row of the group (see choose-row), then the
  ;; value of each aggregate in collector order.
  (define (group-evaluation-rows rows key-procs collector width)
    (let ([specs (collector-specs collector)])
      (map (lambda (group) (evaluation-row group specs width))
           (if (null? key-procs)
               (list rows) ; a single group, even with no rows
               (split-groups rows key-procs)))))

  ;; Groups in order of first appearance; rows with equal keys (NULLs equal) share a group.
  (define (split-groups rows key-procs)
    (let ([table (make-hashtable equal-hash equal?)] [order '()])
      (for-each
       (lambda (row)
         (let* ([key (map (lambda (f) (value-key (f row))) key-procs)]
                [cell (hashtable-ref table key #f)])
           (if cell
               (vector-set! cell 0 (cons row (vector-ref cell 0)))
               (let ([cell (vector (list row))])
                 (hashtable-set! table key cell)
                 (set! order (cons cell order))))))
       rows)
      (map (lambda (cell) (reverse (vector-ref cell 0))) (reverse order))))

  (define (evaluation-row group specs width)
    (let* ([results (map (lambda (spec) (compute-aggregate spec group)) specs)]
           [row (choose-row group specs results width)])
      (list->vector (append (vector->list row) results))))

  ;; The row a bare column reads (3.3): with exactly one aggregate and it min or max, the row that
  ;; gave the extreme; otherwise the first row; all NULL for an empty group.
  (define (choose-row group specs results width)
    (cond
      [(null? group) (make-vector width sql-null)]
      [(and (= (length specs) 1) (extreme-kind? (agg-spec-kind (car specs))))
       (let ([arg (car (agg-spec-args (car specs)))] [best (car results)])
         (or (find-row (lambda (r) (let ([v (arg r)])
                                     (and (not (sql-null? v)) (= 0 (compare-values v best)))))
                       group)
             (car group)))]
      [else (car group)]))

  (define (find-row pred rows)
    (cond [(null? rows) #f] [(pred (car rows)) (car rows)] [else (find-row pred (cdr rows))]))

  ;; produced: list of (result . keys). Keeps the first of each equal result (NULLs equal).
  (define (distinct-results produced)
    (let ([seen (make-hashtable equal-hash equal?)])
      (filter (lambda (p)
                (let ([key (map value-key (car p))])
                  (and (not (hashtable-ref seen key #f))
                       (begin (hashtable-set! seen key #t) #t))))
              produced))))
