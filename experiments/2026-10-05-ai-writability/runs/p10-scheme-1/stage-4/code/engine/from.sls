;;; The FROM clause (4.1): resolving the sources and producing the joined rows.
(library (engine from)
  (export plan-from)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine scope)
          (engine expr))

  ;; Plans a from-item. prepare-select is the SELECT planner (see (engine expr)), used for
  ;; subqueries in FROM; outer is the link to the enclosing query or #f. Returns two values: the
  ;; list of sources, and a thunk giving the joined rows (vectors of the sources' columns side by
  ;; side). All names are resolved here, before any row is read.
  (define (plan-from db item outer prepare-select)
    (cond
      [(from-join? item) (plan-join db item outer prepare-select)]
      [else (let-values ([(source rows) (plan-source db item 0 '() prepare-select)])
              (values (list source) rows))]))

  ;; A table or a subquery as a source whose columns start at offset in the joined row.
  (define (plan-source db item offset hidden prepare-select)
    (cond
      [(from-table? item)
       (let* ([nm (from-table-name item)]
              [table (or (database-find-table db (name-lower nm))
                         (raise-sql-error (string-append "no such table: " (name-text nm))))]
              [alias (from-table-alias item)])
         (values (make-source (name-lower (or alias nm)) (table-columns table) offset hidden)
                 (lambda () (table-rows table))))]
      [else
       (let ([alias (from-subquery-alias item)])
         (let-values ([(cols run) (prepare-select db (from-subquery-stmt item) #f)])
           (values (make-source (and alias (name-lower alias)) cols offset hidden)
                   (let ([cache #f]) ; the subquery is not correlated: it runs once
                     (lambda ()
                       (unless cache (set! cache (map list->vector (run))))
                       cache)))))]))

  (define (plan-join db item outer prepare-select)
    (let-values ([(left-sources left-rows) (plan-from db (from-join-left item) outer prepare-select)])
      (let* ([constraint (from-join-constraint item)]
             [using (and constraint (eq? (car constraint) 'using) (cdr constraint))]
             [offset (apply + (map source-width left-sources))])
        (let-values ([(right right-rows)
                      (plan-source db (from-join-right item) offset
                                   (if using (map name-lower using) '()) prepare-select)])
          (let* ([sources (append left-sources (list right))]
                 [scope (make-scope db sources outer)]
                 [test (cond [using (compile-expr (using-condition using left-sources right) scope)]
                             [constraint (compile-expr (cdr constraint) scope)]
                             [else #f])])
            (values sources
                    (lambda ()
                      (join-rows (from-join-kind item) (left-rows) (right-rows) test
                                 (source-width right)))))))))

  ;; USING (c, ...) as `A.c = B.c AND ...` over slots: A.c is the first source on the left that
  ;; has column c.
  (define (using-condition names left-sources right)
    (let ([terms (map (lambda (nm)
                        (let ([l (find-column-slot left-sources (name-lower nm))]
                              [r (find-column-slot (list right) (name-lower nm))])
                          (unless (and l r)
                            (raise-sql-error
                             (string-append "cannot join using column " (name-text nm)
                                            " - column not present in both tables")))
                          (list 'binop 'eq l r)))
                      names)])
      (fold-left (lambda (acc t) (list 'binop 'and acc t)) (car terms) (cdr terms))))

  ;; (slot index column) for the first column of this lowercase name in the sources, or #f.
  (define (find-column-slot sources lower)
    (let loop ([ss sources])
      (and (pair? ss)
           (let* ([cols (source-columns (car ss))] [n (vector-length cols)])
             (let scan ([i 0])
               (cond [(= i n) (loop (cdr ss))]
                     [(string=? (column-lower (vector-ref cols i)) lower)
                      (list 'slot (+ (source-offset (car ss)) i) (vector-ref cols i))]
                     [else (scan (+ i 1))]))))))

  (define (concat-rows a b)
    (let* ([na (vector-length a)] [v (make-vector (+ na (vector-length b)))])
      (do ([i 0 (+ i 1)]) ((= i na))
        (vector-set! v i (vector-ref a i)))
      (do ([j 0 (+ j 1)]) ((= j (vector-length b)) v)
        (vector-set! v (+ na j) (vector-ref b j)))))

  ;; kind: cross, inner or left; test: #f or a procedure on a joined row; right-width: columns
  ;; of the right source (the NULL extension of a LEFT JOIN).
  (define (join-rows kind left-rows right-rows test right-width)
    (let ([nulls (make-vector right-width sql-null)])
      (apply append
             (map (lambda (l)
                    (let ([pairs (filter (lambda (row) (or (not test) (eq? #t (truth (test row)))))
                                         (map (lambda (r) (concat-rows l r)) right-rows))])
                      (if (and (null? pairs) (eq? kind 'left))
                          (list (concat-rows l nulls))
                          pairs)))
                  left-rows)))))
