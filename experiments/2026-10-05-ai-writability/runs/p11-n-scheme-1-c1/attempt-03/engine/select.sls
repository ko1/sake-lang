;;; SELECT (1.7, 3.x, 4.x): name resolution, filtering, grouping, projection, DISTINCT, ORDER BY, LIMIT.
;;; A select is first prepared (every name resolved and expression compiled, so name errors come
;;; before any row is read), then run. Subqueries use the same two steps (see (engine expr)).
(library (engine select)
  (export execute-select prepare-select call-with-statement-ctes)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine scope)
          (engine expr) (engine from) (engine aggregate) (engine orderby) (engine group)
          (engine compound) (engine ctes) (engine window))

  ;; Returns the result rows: a list of lists of values.
  (define (execute-select db stmt)
    (let-values ([(columns run) (prepare-select db stmt #f)])
      (run)))

  ;; outer: the link to the enclosing query, or #f. Returns two values: a vector of column (the
  ;; result columns, with the affinity of a plain column reference), and a thunk running the
  ;; select and returning its rows. stmt is a select, a compound select or a WITH around one.
  (define (prepare-select db stmt outer)
    (cond
      [(select-stmt? stmt) (prepare-simple db stmt outer)]
      [(compound? stmt) (prepare-compound db stmt outer prepare-select)]
      [else (call-with-statement-ctes db stmt
                                      (lambda () (prepare-select db (with-stmt-body stmt) outer)))]))

  ;; Calls thunk with the ctes of the WITH statement visible (for a SELECT or an INSERT body).
  (define (call-with-statement-ctes db stmt thunk)
    (call-with-ctes db stmt prepare-select thunk))

  (define (prepare-simple db stmt outer)
    (let-values ([(sources source-rows) (plan-sources db (select-stmt-from stmt) outer)])
      (let* ([base (scope-with-window-defs (make-scope db sources outer) (select-stmt-windows stmt))]
             [items (expand-items (select-stmt-items stmt) sources)]
             [aliases (alias-list items)]
             [group (select-stmt-group stmt)]
             [having (select-stmt-having stmt)]
             [aggregate? (or (pair? group) (exists (lambda (it) (find-aggregate (car it))) items))]
             [collector (make-collector)]
             [windows (make-window-collector)])
        (when (and having (not aggregate?)) (raise-sql-error "HAVING clause on a non-aggregate query"))
        (let* ([result-scope (scope-with-windows (if aggregate?
                                                      (make-aggregate-scope base '() collector)
                                                      base)
                                                  windows)]
               [clause-scope (if aggregate?
                                 (make-aggregate-scope base aliases collector)
                                 (make-misuse-scope base aliases misuse-in-order-by misuse-in-order-by))]
               [where (compile-optional (select-stmt-where stmt) (scope-with-aliases base aliases))]
               [key-procs (compile-group-terms group items base aliases)]
               [project (map (lambda (it) (compile-expr (car it) result-scope)) items)]
               ;; DISTINCT compares each result column under its expression's collation (7.4)
               [item-colls (map (lambda (it)
                                  (let ([info (expr-collation (car it) result-scope)]) (if info (cdr info) 'binary)))
                                items)]
               [having (compile-optional having clause-scope)]
               [terms (compile-order-terms (select-stmt-order stmt) items
                                           (scope-with-windows clause-scope windows))]
               [limit (compile-bound (select-stmt-limit stmt) base)]
               [offset (compile-bound (select-stmt-offset stmt) base)]
               [width (scope-width base)])
          (window-collector-base-set! windows
                                      (+ width (if aggregate? (length (collector-specs collector)) 0)))
          (values
           (result-columns items result-scope)
           (lambda ()
             (let* ([kept (filter-rows where (source-rows))]
                    [evaluated (if aggregate?
                                   (filter-rows having (group-evaluation-rows kept key-procs collector width))
                                   kept)]
                    [evaluated (add-window-values windows evaluated)]
                    [produced (map (lambda (row)
                                     (let ([res (map (lambda (f) (f row)) project)])
                                       (cons res (map (lambda (t) ((car t) row res)) terms))))
                                   evaluated)]
                    [distinct (if (select-stmt-distinct? stmt) (distinct-results produced item-colls) produced)]
                    [offset (let ([n (and offset (offset))]) (and n (max n 0)))])
               (map car (take-window (sort-produced terms distinct) offset (and limit (limit)))))))))))

  ;; The sources of FROM and a thunk for the joined rows; without FROM, none and one empty row.
  (define (plan-sources db from outer)
    (if from
        (plan-from db from outer prepare-select)
        (values '() (lambda () (list (vector))))))

  ;; The result columns as column records: named by alias, else by the column of a plain column
  ;; reference, else unnamed. Each has the collation of its expression (7.5), #f if none.
  (define (result-columns items scope)
    (list->vector
     (map (lambda (it)
            (let* ([expr (car it)] [alias (cdr it)]
                   [nm (cond [alias (name-text alias)]
                             [(eq? (car expr) 'col) (name-text (cadr expr))]
                             [(eq? (car expr) 'qcol) (name-text (caddr expr))]
                             [(eq? (car expr) 'slot) (column-name (caddr expr))]
                             [else ""])]
                   [plain? (memq (car expr) '(col qcol slot collate))])
              (make-column nm (string-downcase nm) (and plain? (expr-affinity expr scope)) #f #f
                           (expr-collation expr scope))))
          items)))

  (define (misuse-in-order-by name) (string-append "misuse of aggregate: " name "()"))
  (define (misuse-in-group-by name) "aggregate functions are not allowed in the GROUP BY clause")

  (define (compile-optional expr scope) (and expr (compile-expr expr scope)))

  (define (filter-rows test rows)
    (if test (filter (lambda (row) (eq? #t (truth (test row)))) rows) rows))

  ;; Items as a list of (expression . alias-or-#f); `*` becomes one slot per column, leaving out
  ;; the right-hand copy of a USING column (4.2); `q.*` has every column of source q.
  (define (expand-items items sources)
    (apply append
     (map
      (lambda (it)
        (let ([e (result-column-expr it)])
          (cond
            [(eq? e 'star)
             (when (null? sources) (raise-sql-error "no tables specified"))
             (apply append (map (lambda (s) (source-slots s (source-hidden s))) sources))]
            [(eq? (car e) 'qstar)
             (let ([src (find (lambda (s) (equal? (source-name s) (name-lower (cadr e)))) sources)])
               (unless src (raise-sql-error (string-append "no such table: " (name-text (cadr e)))))
               (source-slots src '()))]
            [else (list (cons e (result-column-alias it)))])))
      items)))

  (define (source-slots src hidden)
    (let loop ([i (- (source-width src) 1)] [acc '()])
      (if (< i 0)
          acc
          (let ([c (vector-ref (source-columns src) i)])
            (loop (- i 1)
                  (if (member (column-lower c) hidden)
                      acc
                      (cons (cons (list 'slot (+ (source-offset src) i) c) #f) acc)))))))

  (define (alias-list items)
    (let loop ([items items] [acc '()])
      (cond [(null? items) (reverse acc)]
            [(cdar items) (loop (cdr items) (cons (cons (name-lower (cdar items)) (caar items)) acc))]
            [else (loop (cdr items) acc)])))

  ;; GROUP BY terms (3.3) as (procedure . collation), the procedure on a source row. An integer k
  ;; means the k-th result column; `term COLLATE n` groups under n.
  (define (compile-group-terms terms items base aliases)
    (let ([scope (make-misuse-scope base aliases misuse-in-group-by misuse-in-group-by)]
          [n (length items)])
      (let loop ([terms terms] [i 1] [acc '()])
        (if (null? terms)
            (reverse acc)
            (let* ([collate? (eq? (car (car terms)) 'collate)]
                   [term (if collate? (cadr (car terms)) (car terms))]
                   [explicit (and collate? (collation-symbol (caddr (car terms))))]
                   [k (ordinal-of term)]
                   [expr (cond [(not k) term]
                               [(and (>= k 1) (<= k n)) (car (list-ref items (- k 1)))]
                               [else (raise-sql-error
                                      (string-append (ordinal-name i)
                                                     " GROUP BY term out of range - should be between 1 and "
                                                     (number->string n)))])]
                   [info (expr-collation expr scope)])
              (loop (cdr terms) (+ i 1)
                    (cons (cons (compile-expr expr scope) (or explicit (if info (cdr info) 'binary)))
                          acc)))))))

  (install-subquery-planner! prepare-select))
