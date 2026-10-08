;;; (engine select) -- running a SELECT statement (spec 1.7).
;;;
;;; plan-select resolves every name and returns a plan; running the plan gives the result
;;; rows (vectors of values).  run-select does both.  A subquery is planned once, at the
;;; point of its expression, and run per row of the enclosing query if it is correlated.
(library (engine select)
  (export run-select plan-select)
  (import (rnrs) (engine errors) (engine values) (engine ast)
          (engine catalog) (engine sources) (engine plan) (engine joins) (engine expr)
          (engine ordering) (engine grouping) (engine aggregation))

  (define (no-scope db) (make-scope (make-level db '() #f) '()))

  ;;; ---- result columns --------------------------------------------------------

  ;; ast: the expression (a * is already expanded into column references); cexpr: compiled;
  ;; aggregate: the written name of the first aggregate call in it, or #f.
  (define-record-type result-column (fields ast alias cexpr aggregate))

;; List of (ast . alias-or-#f), with * expanded into references to the columns themselves.
  (define (expand-items items sources)
    (define (slots entries) (map (lambda (e) (cons (list 'slot (car e)) #f)) entries))
    (apply append
           (map (lambda (item)
                  (cond
                    [(eq? item 'star)
                     (when (null? sources) (raise-sql-error "no tables specified"))
                     (slots (sources-star-columns sources))]
                    [(qualified-star? item)
                     (let ([source (sources-named sources (ascii-downcase (qualified-star-qualifier item)))])
                       (unless source
                         (raise-sql-error (string-append "no such table: " (qualified-star-qualifier item))))
                       (slots (source-all-columns source)))]
                    [else (list (cons (select-item-expr item) (select-item-alias item)))]))
                items)))

  ;; Compile the items in `scope`, whose aggregate collector learns which calls they hold.
  (define (compile-result-columns expanded scope collector)
    (map (lambda (item)
           (let* ([cexpr (compile-expr (car item) scope)]
                  [used (collector-take-used! collector)])
             (make-result-column (car item) (cdr item) cexpr (and (pair? used) (car used)))))
         expanded))

  ;; alist lower-cased alias -> (index . (entry column)) for the columns with an alias.
  (define (alias-table columns entry)
    (let loop ([cols columns] [i 0] [acc '()])
      (cond [(null? cols) (reverse acc)]
            [(result-column-alias (car cols))
             (loop (cdr cols) (+ i 1)
                   (cons (cons (ascii-downcase (result-column-alias (car cols)))
                               (cons i (entry (car cols))))
                         acc))]
            [else (loop (cdr cols) (+ i 1) acc)])))

  ;; In WHERE, an alias of a column holding an aggregate call is an error.
  (define (where-alias-entry column)
    (if (result-column-aggregate column)
        (misuse-in-order-by (result-column-aggregate column))
        (result-column-cexpr column)))

  ;;; ---- GROUP BY ----------------------------------------------------------------

  ;; A term that is a position or an alias is replaced by that result column's expression;
  ;; a name that is a column of the table stays (1.7, 3.3).  Returns a procedure of an input row.
  (define (plan-group-term expr position columns scope)
    (let* ([k (position-term expr)]
           [alias (and (eq? (car expr) 'col) (not (cadr expr))
                       (not (scope-has-column? scope (ascii-downcase (caddr expr))))
                       (find (lambda (c) (and (result-column-alias c)
                                              (string=? (ascii-downcase (result-column-alias c))
                                                        (ascii-downcase (caddr expr)))))
                             columns))])
      (cexpr-proc
       (compile-expr
        (cond [k (unless (<= 1 k (length columns))
                   (raise-sql-error (string-append (ordinal position)
                                                   " GROUP BY term out of range - should be between 1 and "
                                                   (number->string (length columns)))))
                 (result-column-ast (list-ref columns (- k 1)))]
              [alias (result-column-ast alias)]
              [else expr])
        scope))))

  ;;; ---- ORDER BY ----------------------------------------------------------------

  ;; The k of an ORDER BY / GROUP BY term that is an integer literal (or minus one), else #f.
  (define (position-term expr)
    (cond [(and (eq? (car expr) 'lit) (integer-value? (cadr expr))) (cadr expr)]
          [(and (eq? (car expr) 'neg) (eq? (car (cadr expr)) 'lit) (integer-value? (cadr (cadr expr))))
           (- (cadr (cadr expr)))]
          [else #f]))

  ;; A term becomes a procedure (input-row result-row) -> sort key value.
  (define (plan-order-term term position nresult aliases scope)
    (let* ([expr (order-term-expr term)]
           [k (position-term expr)]
           [alias (and (eq? (car expr) 'col) (not (cadr expr))
                       (assoc (ascii-downcase (caddr expr)) aliases))])
      (cond
        [k (unless (<= 1 k nresult)
             (raise-sql-error (string-append (ordinal position)
                                             " ORDER BY term out of range - should be between 1 and "
                                             (number->string nresult))))
           (lambda (row result) (vector-ref result (- k 1)))]
        [alias (let ([i (cadr alias)]) (lambda (row result) (vector-ref result i)))]
        [else (let ([p (cexpr-proc (compile-expr expr scope))])
                (lambda (row result) (p row)))])))

  ;;; ---- LIMIT / OFFSET ---------------------------------------------------------------

  ;; The integer a LIMIT/OFFSET expression gives (no row in scope).
  (define (constant-integer db expr)
    (let ([v ((cexpr-proc (compile-expr expr (no-scope db))) (vector))])
      (cond [(sql-null? v) 0]
            [(string? v) (constant-integer-of (text->number-prefix v))]
            [else (constant-integer-of v)])))
  (define (constant-integer-of n) (if (integer-value? n) n (exact (truncate n))))

  (define (drop-rows rows n)
    (let loop ([rows rows] [n n]) (if (or (<= n 0) (null? rows)) rows (loop (cdr rows) (- n 1)))))
  (define (take-rows rows n)
    (let loop ([rows rows] [n n] [acc '()])
      (if (or (<= n 0) (null? rows)) (reverse acc) (loop (cdr rows) (- n 1) (cons (car rows) acc)))))

  ;;; ---- the statement ------------------------------------------------------------------

  (define (indexed-map f lst)
    (let loop ([lst lst] [i 1])
      (if (null? lst) '() (cons (f (car lst) i) (loop (cdr lst) (+ i 1))))))

  (define (truthy-row-filter proc rows)
    (filter (lambda (row) (eq? (truth (proc row)) #t)) rows))

  ;; The name of a result column as a subquery source sees it: its alias, or the column's name.
  (define (result-name column sources)
    (or (result-column-alias column)
        (let ([ast (result-column-ast column)])
          (case (car ast)
            [(col) (caddr ast)]
            [(slot) (column-name (sources-ref sources (cadr ast)))]
            [else #f]))))

  ;; A plain column reference gives its column's affinity to the result column (1.9).
  (define (result-affinity column)
    (and (memq (car (result-column-ast column)) '(col slot))
         (cexpr-affinity (result-column-cexpr column))))

  ;; outer: the scope the statement is a subquery in, or #f.
  (define (plan-select db stmt outer)
    (let* ([correlation (make-correlation)])
      (let-values ([(sources from-rows) (plan-from db (select-stmt-from stmt) outer correlation plan-select)])
        (plan-query db stmt outer correlation sources from-rows))))

  (define (plan-query db stmt outer correlation sources from-rows)
    (let* ([level (make-level db sources outer correlation)]
           [ncols (sources-width sources)]
           [collector (make-aggregate-collector ncols)]
           [columns (compile-result-columns (expand-items (select-stmt-items stmt) sources)
                                            (make-scope level '() collector) collector)]
           [group-procs (indexed-map (lambda (g i)
                                       (plan-group-term g i columns
                                                        (make-scope level '() misuse-in-group-by)))
                                     (select-stmt-group-by stmt))]
           [aggregate? (or (pair? group-procs) (pair? (collector-specs collector)))]
           [_ (when (and (select-stmt-having stmt) (not aggregate?))
                (raise-sql-error "HAVING clause on a non-aggregate query"))]
           [where (and (select-stmt-where stmt)
                       (cexpr-proc (compile-expr (select-stmt-where stmt)
                                                 (make-scope level (alias-table columns where-alias-entry)))))]
           [aliases (alias-table columns result-column-cexpr)]
           ;; HAVING and ORDER BY may use aggregates only in an aggregate query
           [post-scope (make-scope level aliases (if aggregate? collector misuse-in-order-by))]
           [having (and (select-stmt-having stmt)
                        (cexpr-proc (compile-expr (select-stmt-having stmt) post-scope)))]
           [terms (select-stmt-order-by stmt)]
           [key-procs (indexed-map (lambda (t i) (plan-order-term t i (length columns) aliases post-scope))
                                   terms)]
           [result-procs (map (lambda (c) (cexpr-proc (result-column-cexpr c))) columns)]
           [limit (and (select-stmt-limit stmt) (constant-integer db (select-stmt-limit stmt)))]
           [offset (if (select-stmt-offset stmt) (constant-integer db (select-stmt-offset stmt)) 0)])
      (make-plan
       (map (lambda (c) (result-name c sources)) columns)
       (map result-affinity columns)
       (level-correlated? level)
       (lambda ()
         (run-query (from-rows) where aggregate? group-procs collector ncols having
                    result-procs key-procs terms (select-stmt-distinct stmt) limit offset)))))

  ;; The pipeline over the joined rows: WHERE, grouping, HAVING, projection, DISTINCT,
  ;; ORDER BY, OFFSET, LIMIT.
  (define (run-query input where aggregate? group-procs collector ncols having
                     result-procs key-procs terms distinct? limit offset)
    (let* ([kept (if where (truthy-row-filter where input) input)]
           [rows (if aggregate?
                     (let* ([groups (if (null? group-procs)
                                        (list kept)
                                        (partition-rows (lambda (row) (map (lambda (p) (p row)) group-procs))
                                                        kept))]
                            [group-rows (map (lambda (g) (group-row (collector-specs collector) ncols g)) groups)])
                       (if having (truthy-row-filter having group-rows) group-rows))
                     kept)]
           ;; each entry: (sort-keys . result-row)
           [entries (map (lambda (row)
                           (let ([result (list->vector (map (lambda (p) (p row)) result-procs))])
                             (cons (map (lambda (kp) (kp row result)) key-procs) result)))
                         rows)]
           [distinct (if distinct?
                         (distinct-by (lambda (entry) (vector->list (cdr entry))) entries)
                         entries)]
           [sorted (if (null? terms)
                       distinct
                       (list-sort (lambda (x y) (< (compare-keys terms (car x) (car y)) 0)) distinct))]
           [paged (drop-rows (map cdr sorted) offset)])
      (if (and limit (>= limit 0)) (take-rows paged limit) paged)))

  (define (run-select db stmt) ((plan-run (plan-select db stmt #f))))

  (install-subquery-planner! plan-select))
