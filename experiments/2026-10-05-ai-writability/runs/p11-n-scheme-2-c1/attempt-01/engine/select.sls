;;; (engine select) -- planning one simple SELECT (spec 1.7, 3, 4).
;;;
;;; plan-simple-select resolves every name and returns a plan; running the plan gives the
;;; result rows (vectors of values).  WITH, compound selects and views are put around it by
;;; (engine query).  A subquery is planned once, at the point of its expression, and run per
;;; row of the enclosing query if it is correlated.
(library (engine select)
  (export plan-simple-select)
  (import (rnrs) (engine errors) (engine values) (engine ast)
          (engine catalog) (engine sources) (engine plan) (engine joins) (engine expr)
          (engine ordering) (engine grouping) (engine aggregation) (engine paging) (engine windows))

  ;;; ---- result columns --------------------------------------------------------

  ;; ast: the expression (a * is already expanded into column references); cexpr: compiled;
  ;; aggregate, window: the written name of the first aggregate / window call in it, or #f.
  (define-record-type result-column (fields ast alias cexpr aggregate window))

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

  ;; Compile the items in `scope`, whose aggregate and window collectors learn which calls they hold.
  (define (compile-result-columns expanded scope collector windows)
    (map (lambda (item)
           (let* ([cexpr (compile-expr (car item) scope)]
                  [used (collector-take-used! collector)]
                  [windows-used (window-collector-take-used! windows)])
             (make-result-column (car item) (cdr item) cexpr (and (pair? used) (car used))
                                 (and (pair? windows-used) (car windows-used)))))
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

  ;; In WHERE, an alias of a column holding an aggregate or window call is an error.
  (define (where-alias-entry column)
    (cond [(result-column-aggregate column) (misuse-in-order-by (result-column-aggregate column))]
          [(result-column-window column)
           (string-append "misuse of aliased window function " (result-column-alias column))]
          [else (result-column-cexpr column)]))

  ;;; ---- GROUP BY ----------------------------------------------------------------

  ;; A term that is a position or an alias is replaced by that result column's expression;
  ;; a name that is a column of the table stays (1.7, 3.3).  Returns a procedure of an input row
  ;; giving the grouping key: the value under the term's collation (7.4), which is a written
  ;; COLLATE, else the collation of the expression the term stands for.
  (define (plan-group-term term position columns scope)
    (let* ([collate? (eq? (car term) 'collate)]
           [explicit (and collate? (lookup-collation (caddr term)))]
           [expr (if collate? (cadr term) term)]
           [k (position-term expr)]
           [alias (and (eq? (car expr) 'col) (not (cadr expr))
                       (not (scope-has-column? scope (ascii-downcase (caddr expr))))
                       (find (lambda (c) (and (result-column-alias c)
                                              (string=? (ascii-downcase (result-column-alias c))
                                                        (ascii-downcase (caddr expr)))))
                             columns))])
      (let ([c (compile-expr
                (cond [k (unless (<= 1 k (length columns))
                           (raise-sql-error (string-append (ordinal position)
                                                           " GROUP BY term out of range - should be between 1 and "
                                                           (number->string (length columns)))))
                         (result-column-ast (list-ref columns (- k 1)))]
                      [alias (result-column-ast alias)]
                      [else term])
                scope)])
        (collate-proc (cexpr-proc c)
                      (if (or k alias) (or explicit (coll-symbol (cexpr-coll c))) (coll-symbol (cexpr-coll c)))))))

  ;;; ---- ORDER BY ----------------------------------------------------------------

  ;; A term becomes a procedure (input-row result-row) -> sort key value: the value under the
  ;; term's collation (7.4), which is a written COLLATE, else the collation of the result column
  ;; or expression the term stands for.
  (define (plan-order-term term position columns aliases scope)
    (let* ([full (order-term-expr term)]
           [collate? (eq? (car full) 'collate)]
           [explicit (and collate? (lookup-collation (caddr full)))]
           [expr (if collate? (cadr full) full)]
           [nresult (length columns)]
           [k (position-term expr)]
           [alias (and (eq? (car expr) 'col) (not (cadr expr))
                       (assoc (ascii-downcase (caddr expr)) aliases))])
      ;; result column `index`, whose expression has collation `coll` (or #f)
      (define (result-key index coll)
        (let ([c (or explicit (coll-symbol coll))])
          (lambda (row result) (collate-value (vector-ref result index) c))))
      (cond
        [k (unless (<= 1 k nresult)
             (raise-sql-error (string-append (ordinal position)
                                             " ORDER BY term out of range - should be between 1 and "
                                             (number->string nresult))))
           (result-key (- k 1) (cexpr-coll (result-column-cexpr (list-ref columns (- k 1)))))]
        [alias (result-key (cadr alias) (cexpr-coll (cddr alias)))]
        [else (let* ([c (compile-expr full scope)]
                     [p (collate-proc (cexpr-proc c) (coll-symbol (cexpr-coll c)))])
                (lambda (row result) (p row)))])))

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

  ;; outer: the scope the statement is a subquery in, or #f.  plan-nested plans the queries
  ;; nested in its FROM (any select, with its own WITH).
  (define (plan-simple-select db stmt outer plan-nested)
    (let* ([correlation (make-correlation)])
      (let-values ([(sources from-rows) (plan-from db (select-stmt-from stmt) outer correlation plan-nested)])
        (plan-query db stmt outer correlation sources from-rows))))

  (define (plan-query db stmt outer correlation sources from-rows)
    (let* ([level (make-level db sources outer correlation)]
           [ncols (sources-width sources)]
           [collector (make-aggregate-collector ncols)]
           [windows (make-window-collector (select-stmt-windows stmt))]
           [columns (compile-result-columns (expand-items (select-stmt-items stmt) sources)
                                            (make-scope level '() collector windows) collector windows)]
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
           [aggregates (if aggregate? collector misuse-in-order-by)]
           [post-scope (make-scope level aliases aggregates windows)]
           [having (and (select-stmt-having stmt)
                        (cexpr-proc (compile-expr (select-stmt-having stmt)
                                                  (make-scope level aliases aggregates))))]
           [terms (select-stmt-order-by stmt)]
           [key-procs (indexed-map (lambda (t i) (plan-order-term t i columns aliases post-scope))
                                   terms)]
           [result-procs (map (lambda (c) (cexpr-proc (result-column-cexpr c))) columns)]
           [result-colls (map (lambda (c) (coll-symbol (cexpr-coll (result-column-cexpr c)))) columns)]
           [limit (and (select-stmt-limit stmt) (constant-integer db (select-stmt-limit stmt)))]
           [offset (if (select-stmt-offset stmt) (constant-integer db (select-stmt-offset stmt)) 0)])
      (make-plan
       (map (lambda (c) (result-name c sources)) columns)
       (map result-affinity columns)
       (map (lambda (c) (cexpr-coll (result-column-cexpr c))) columns)
       (level-correlated? level)
       (lambda ()
         (run-query (from-rows) where aggregate? group-procs collector ncols having windows
                    result-procs key-procs terms (select-stmt-distinct stmt) result-colls limit offset)))))

  ;; The pipeline over the joined rows: WHERE, grouping, HAVING, window functions, projection, DISTINCT,
  ;; ORDER BY, OFFSET, LIMIT.
  (define (run-query input where aggregate? group-procs collector ncols having windows
                     result-procs key-procs terms distinct? result-colls limit offset)
    (let* ([kept (if where (truthy-row-filter where input) input)]
           [rows (if aggregate?
                     (let* ([groups (if (null? group-procs)
                                        (list kept)
                                        (partition-rows (lambda (row) (map (lambda (p) (p row)) group-procs))
                                                        kept))]
                            [group-rows (map (lambda (g) (group-row (collector-specs collector) ncols g)) groups)])
                       (if having (truthy-row-filter having group-rows) group-rows))
                     kept)]
           [rows (if (null? (window-collector-calls windows))
                     rows
                     (append-window-values (window-collector-calls windows) rows))]
           ;; each entry: (sort-keys . result-row)
           [entries (map (lambda (row)
                           (let ([result (list->vector (map (lambda (p) (p row)) result-procs))])
                             (cons (map (lambda (kp) (kp row result)) key-procs) result)))
                         rows)]
           [distinct (if distinct?
                         (distinct-by (lambda (entry) (map collate-value (vector->list (cdr entry)) result-colls))
                                      entries)
                         entries)]
           [sorted (if (null? terms)
                       distinct
                       (list-sort (lambda (x y) (< (compare-keys terms (car x) (car y)) 0)) distinct))])
      (page-rows (map cdr sorted) limit offset))))
