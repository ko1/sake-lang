;;; (engine joins) -- the FROM clause: its sources and the joined rows (spec 4.1).
;;;
;;; plan-from resolves every table, column and USING name up front; the procedure it returns
;;; builds the joined rows (vectors: the sources' rows side by side) when called.
(library (engine joins)
  (export plan-from)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine catalog)
          (engine sources) (engine plan) (engine expr))

  (define (null-row n) (make-vector n sql-null))

  ;; A column for a result column of a subquery source (affinity as its type, or #f; collation:
  ;; the plan's entry for the column, #f or (kind . collation); the column's is binary if none, 7.5).
  (define (derived-column name affinity collation)
    (let ([name (or name "")])
      (make-column name (ascii-downcase name) affinity #f sql-null (if collation (cdr collation) 'binary))))

;; The source's column names: those listed (a view's or cte's column list, #f for none),
  ;; then the plan's own for the rest.
  (define (source-column-names listed plan)
    (let loop ([own (plan-names plan)] [listed (or listed '())])
      (cond [(null? own) '()]
            [(null? listed) own]
            [else (cons (car listed) (loop (cdr own) (cdr listed)))])))

  ;; -> (values name columns rows-thunk) for a source that is a query's plan.
  (define (plan-source name listed plan)
    (values name
            (list->vector (map derived-column (source-column-names listed plan) (plan-affinities plan)
                               (plan-collations plan)))
            (plan-run plan)))

  ;; A table-ref names a cte, else a table, else a view (a cte hides the other two).
  (define (plan-table-ref db item plan-select)
    (let* ([written (table-ref-name item)]
           [lname (ascii-downcase written)]
           [name (or (table-ref-alias item) written)]
           [cte (database-find-cte db lname)]
           [tbl (database-find-table db lname)]
           [view (database-find-view db lname)])
      (cond [cte (plan-source name (cte-entry-columns (cdr cte)) ((cte-entry-plan (cdr cte))))]
            [tbl (values name (table-columns tbl) (lambda () (table-rows tbl)))]
            [view (plan-source name (view-columns view)
                               (plan-select (database-without-ctes db) (view-select view) #f))]
            [else (raise-sql-error (string-append "no such table: " written))])))

  ;; -> (values name columns rows-thunk) for a table-ref or subquery-ref.  `plan-select`
  ;; plans a subquery source, which is not correlated with the queries around it.
  (define (plan-item db item plan-select)
    (if (table-ref? item)
        (plan-table-ref db item plan-select)
        (plan-source (subquery-ref-alias item) #f (plan-select db (subquery-ref-select item) #f))))

  (define (using-error name)
    (raise-sql-error (string-append "cannot join using column " name
                                    " - column not present in both tables")))

  ;; USING (c, ...) as a test of the joined row: left c = right c for each.
  (define (using-condition left-sources right-source names)
    (let ([tests
           (map (lambda (name)
                  (let* ([lname (ascii-downcase name)]
                         [lefts (sources-column-matches left-sources lname)]
                         [right (source-column-index right-source lname)])
                    (unless (and (pair? lefts) right) (using-error name))
                    (let* ([l (car lefts)] [r (+ (source-offset right-source) right)]
                           [lcol (sources-ref left-sources l)] [rcol (sources-ref (list right-source) r)])
                      (binary-cexpr '=
                                    (column-cexpr l (column-type lcol) (column-collation lcol))
                                    (column-cexpr r (column-type rcol) (column-collation rcol))))))
                names)])
      (lambda (row) (for-all (lambda (t) (eq? (truth ((cexpr-proc t) row)) #t)) tests))))

  ;; The test of one join over the joined row, or #f for none.
  (define (join-condition db constraint sources right-source outer correlation)
    (cond
      [(not constraint) #f]
      [(eq? (car constraint) 'on)
       (let ([test (cexpr-proc (compile-expr (cdr constraint)
                                             (make-scope (make-level db sources outer correlation) '())))])
         (lambda (row) (eq? (truth (test row)) #t)))]
      [else (using-condition (reverse (cdr (reverse sources))) right-source (cdr constraint))]))

  ;; `left` rows each joined with the `right` rows that pass `test` (#f: all).  A left join
  ;; keeps an unmatched left row, NULL-extended.
  (define (join-rows kind test left right right-width)
    (let loop ([left left] [acc '()])
      (if (null? left)
          (reverse acc)
          (let inner ([rs right] [acc acc] [matched? #f])
            (cond
              [(pair? rs)
               (let ([joined (vector-append (car left) (car rs))])
                 (if (or (not test) (test joined))
                     (inner (cdr rs) (cons joined acc) #t)
                     (inner (cdr rs) acc matched?)))]
              [(and (eq? kind 'left) (not matched?))
               (loop (cdr left) (cons (vector-append (car left) (null-row right-width)) acc))]
              [else (loop (cdr left) acc)])))))

  (define (vector-append a b)
    (let* ([na (vector-length a)] [v (make-vector (+ na (vector-length b)))])
      (do ([i 0 (+ i 1)]) ((= i na)) (vector-set! v i (vector-ref a i)))
      (do ([i 0 (+ i 1)]) ((= i (vector-length b))) (vector-set! v (+ na i) (vector-ref b i)))
      v))

  ;; -> (values sources rows-thunk).  outer: the scope of the enclosing query or #f;
  ;; correlation: that query's correlation box (see (engine expr)).
  (define (plan-from db from outer correlation plan-select)
    (if (not from)
        (values '() (lambda () (list (vector))))
        (let-values ([(name columns rows) (plan-item db (from-clause-first from) plan-select)])
          (let loop ([sources (sources-add '() name columns '())] [rows rows] [joins (from-clause-joins from)])
            (if (null? joins)
                (values sources rows)
                (let ([join (car joins)])
                  (let-values ([(name columns right-rows) (plan-item db (join-clause-item join) plan-select)])
                    (let* ([constraint (join-clause-constraint join)]
                           [hidden (if (and constraint (eq? (car constraint) 'using))
                                       (map ascii-downcase (cdr constraint))
                                       '())]
                           [sources* (sources-add sources name columns hidden)]
                           [right-source (car (reverse sources*))]
                           [test (join-condition db constraint sources* right-source outer correlation)]
                           [kind (join-clause-kind join)]
                           [left-rows rows])
                      (loop sources*
                            (lambda ()
                              (let ([left (left-rows)])
                                (join-rows kind test left (right-rows) (vector-length columns))))
                            (cdr joins)))))))))))
