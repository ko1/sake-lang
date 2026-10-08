;;; SELECT (1.7, 3.x): name resolution, filtering, grouping, projection, DISTINCT, ORDER BY, LIMIT.
(library (engine select)
  (export execute-select)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine expr)
          (engine aggregate) (engine orderby) (engine group))

  ;; Returns the result rows: a list of lists of values.
  (define (execute-select db stmt)
    (let* ([table (find-source db (select-stmt-from stmt))]
           [columns (if table (table-columns table) (vector))]
           [items (expand-items (select-stmt-items stmt) table)]
           [aliases (alias-list items)]
           [group (select-stmt-group stmt)]
           [having (select-stmt-having stmt)]
           [aggregate? (or (pair? group) (exists (lambda (it) (find-aggregate (car it))) items))]
           [collector (make-collector)])
      (when (and having (not aggregate?)) (raise-sql-error "HAVING clause on a non-aggregate query"))
      (let* ([result-scope (if aggregate?
                               (make-aggregate-scope columns '() collector)
                               (make-scope columns '()))]
             [clause-scope (if aggregate?
                               (make-aggregate-scope columns aliases collector)
                               (make-misuse-scope columns aliases misuse-in-order-by misuse-in-order-by))]
             [where (compile-optional (select-stmt-where stmt) (make-scope columns aliases))]
             [key-procs (compile-group-terms group items columns aliases)]
             [project (map (lambda (it) (compile-expr (car it) result-scope)) items)]
             [having (compile-optional having clause-scope)]
             [terms (compile-order-terms (select-stmt-order stmt) items clause-scope)]
             [limit (bound (select-stmt-limit stmt))]
             [offset (bound (select-stmt-offset stmt))]
             [kept (filter-rows where (if table (table-rows table) (list (vector))))]
             [evaluated (if aggregate?
                            (filter-rows having
                                         (group-evaluation-rows kept key-procs collector
                                                                (vector-length columns)))
                            kept)]
             [produced (map (lambda (row)
                              (let ([res (map (lambda (f) (f row)) project)])
                                (cons res (map (lambda (t) ((car t) row res)) terms))))
                            evaluated)]
             [distinct (if (select-stmt-distinct? stmt) (distinct-results produced) produced)])
        (map car (take-window (sort-produced terms distinct) (and offset (max offset 0)) limit)))))

  (define (misuse-in-order-by name) (string-append "misuse of aggregate: " name "()"))
  (define (misuse-in-group-by name) "aggregate functions are not allowed in the GROUP BY clause")

  (define (compile-optional expr scope) (and expr (compile-expr expr scope)))

  (define (filter-rows test rows)
    (if test (filter (lambda (row) (eq? #t (truth (test row)))) rows) rows))

  (define (find-source db from)
    (and from
         (or (database-find-table db (name-lower from))
             (raise-sql-error (string-append "no such table: " (name-text from))))))

  ;; Items as a list of (expression . alias-or-#f); `*` becomes one column reference per column.
  (define (expand-items items table)
    (apply append
     (map
      (lambda (it)
        (if (eq? (result-column-expr it) 'star)
            (begin
              (unless table (raise-sql-error "no tables specified"))
              (map (lambda (c) (cons (list 'col (make-name (column-name c) (column-lower c))) #f))
                   (vector->list (table-columns table))))
            (list (cons (result-column-expr it) (result-column-alias it)))))
      items)))

  (define (alias-list items)
    (let loop ([items items] [acc '()])
      (cond [(null? items) (reverse acc)]
            [(cdar items) (loop (cdr items) (cons (cons (name-lower (cdar items)) (caar items)) acc))]
            [else (loop (cdr items) acc)])))

  ;; GROUP BY terms (3.3) as procedures on a source row. An integer k means the k-th result column.
  (define (compile-group-terms terms items columns aliases)
    (let ([scope (make-misuse-scope columns aliases misuse-in-group-by misuse-in-group-by)]
          [n (length items)])
      (let loop ([terms terms] [i 1] [acc '()])
        (if (null? terms)
            (reverse acc)
            (let* ([k (ordinal-of (car terms))]
                   [expr (cond [(not k) (car terms)]
                               [(and (>= k 1) (<= k n)) (car (list-ref items (- k 1)))]
                               [else (raise-sql-error
                                      (string-append (ordinal-name i)
                                                     " GROUP BY term out of range - should be between 1 and "
                                                     (number->string n)))])])
              (loop (cdr terms) (+ i 1) (cons (compile-expr expr scope) acc)))))))

  ;; LIMIT / OFFSET: an expression evaluated with no row, as an integer; #f when absent.
  (define (bound expr)
    (and expr
         (let ([v ((compile-expr expr no-row-scope) (vector))])
           (cond [(sql-null? v) #f]
                 [else (let ([n (to-number v)]) (if (flonum? n) (exact (truncate n)) n))])))))
