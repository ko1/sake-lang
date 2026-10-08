;;; (engine select) -- running a SELECT statement (spec 1.7).
;;;
;;; run-select returns the result rows (vectors of values).  All name
;;; resolution happens while planning, before the first row is read.
(library (engine select)
  (export run-select)
  (import (rnrs) (engine errors) (engine values) (engine ast)
          (engine catalog) (engine expr) (engine ordering) (engine grouping) (engine aggregation))

  (define (no-scope) (make-scope #f '()))

  ;;; ---- result columns --------------------------------------------------------

  ;; ast: the expression (a * is already expanded into column references); cexpr: compiled;
  ;; aggregate: the written name of the first aggregate call in it, or #f.
  (define-record-type result-column (fields ast alias cexpr aggregate))

  ;; List of (ast . alias-or-#f), with * expanded.
  (define (expand-items items table)
    (apply append
           (map (lambda (item)
                  (if (eq? item 'star)
                      (begin
                        (unless table (raise-sql-error "no tables specified"))
                        (map (lambda (col) (cons (list 'col #f (column-name col)) #f))
                             (vector->list (table-columns table))))
                      (list (cons (select-item-expr item) (select-item-alias item)))))
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
  (define (plan-group-term expr position columns table scope)
    (let* ([k (position-term expr)]
           [alias (and (eq? (car expr) 'col) (not (cadr expr))
                       (not (and table (table-find-column table (ascii-downcase (caddr expr)))))
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
  (define (constant-integer expr)
    (let ([v ((cexpr-proc (compile-expr expr (no-scope))) (vector))])
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

  (define (run-select db stmt)
    (let* ([from (select-stmt-from stmt)]
           [table (and from
                       (or (database-find-table db (ascii-downcase from))
                           (raise-sql-error (string-append "no such table: " from))))]
           [ncols (if table (vector-length (table-columns table)) 0)]
           [collector (make-aggregate-collector ncols)]
           [columns (compile-result-columns (expand-items (select-stmt-items stmt) table)
                                            (make-scope table '() collector) collector)]
           [group-procs (indexed-map (lambda (g i)
                                       (plan-group-term g i columns table
                                                        (make-scope table '() misuse-in-group-by)))
                                     (select-stmt-group-by stmt))]
           [aggregate? (or (pair? group-procs) (pair? (collector-specs collector)))]
           [_ (when (and (select-stmt-having stmt) (not aggregate?))
                (raise-sql-error "HAVING clause on a non-aggregate query"))]
           [where (and (select-stmt-where stmt)
                       (cexpr-proc (compile-expr (select-stmt-where stmt)
                                                 (make-scope table (alias-table columns where-alias-entry)))))]
           [aliases (alias-table columns result-column-cexpr)]
           ;; HAVING and ORDER BY may use aggregates only in an aggregate query
           [post-scope (make-scope table aliases (if aggregate? collector misuse-in-order-by))]
           [having (and (select-stmt-having stmt)
                        (cexpr-proc (compile-expr (select-stmt-having stmt) post-scope)))]
           [terms (select-stmt-order-by stmt)]
           [key-procs (indexed-map (lambda (t i) (plan-order-term t i (length columns) aliases post-scope))
                                   terms)]
           [result-procs (map (lambda (c) (cexpr-proc (result-column-cexpr c))) columns)]
           [limit (and (select-stmt-limit stmt) (constant-integer (select-stmt-limit stmt)))]
           [offset (if (select-stmt-offset stmt) (constant-integer (select-stmt-offset stmt)) 0)]
           [input (if table (table-rows table) (list (vector)))]
           [kept (if where (truthy-row-filter where input) input)]
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
           [distinct (if (select-stmt-distinct stmt)
                         (distinct-by (lambda (entry) (vector->list (cdr entry))) entries)
                         entries)]
           [sorted (if (null? terms)
                       distinct
                       (list-sort (lambda (x y) (< (compare-keys terms (car x) (car y)) 0)) distinct))]
           [paged (drop-rows (map cdr sorted) offset)])
      (if (and limit (>= limit 0)) (take-rows paged limit) paged))))
