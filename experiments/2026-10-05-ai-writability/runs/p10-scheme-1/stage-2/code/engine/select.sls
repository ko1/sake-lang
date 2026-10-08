;;; SELECT (1.7): name resolution, filtering, projection, ORDER BY, LIMIT / OFFSET.
(library (engine select)
  (export execute-select)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine expr))

  ;; Returns the result rows: a list of lists of values.
  (define (execute-select db stmt)
    (let* ([table (find-source db (select-stmt-from stmt))]
           [columns (if table (table-columns table) (vector))]
           [items (expand-items (select-stmt-items stmt) table)]
           [aliases (alias-list items)]
           [column-scope (make-scope columns '())]
           [full-scope (make-scope columns aliases)]
           [project (map (lambda (it) (compile-expr (car it) column-scope)) items)]
           [where (and (select-stmt-where stmt) (compile-expr (select-stmt-where stmt) full-scope))]
           [terms (compile-order-terms (select-stmt-order stmt) items full-scope)]
           [limit (bound (select-stmt-limit stmt))]
           [offset (bound (select-stmt-offset stmt))]
           [source (if table (table-rows table) (list (vector)))]
           [kept (if where
                     (filter (lambda (row) (eq? #t (truth (where row)))) source)
                     source)]
           [produced (map (lambda (row)
                            (let ([res (map (lambda (f) (f row)) project)])
                              (cons res (map (lambda (t) ((car t) row res)) terms))))
                          kept)]
           [ordered (if (null? terms) produced (list-sort (lambda (a b) (sort-before? terms a b)) produced))])
      (map car (take-window ordered (and offset (max offset 0)) limit))))

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

  ;; LIMIT / OFFSET: an expression evaluated with no row, as an integer; #f when absent.
  (define (bound expr)
    (and expr
         (let ([v ((compile-expr expr no-row-scope) (vector))])
           (cond [(sql-null? v) #f]
                 [else (let ([n (to-number v)]) (if (flonum? n) (exact (truncate n)) n))]))))

  (define (take-window rows offset limit)
    (let* ([rest (if (and offset (> offset 0)) (list-tail* rows offset) rows)])
      (if (and limit (>= limit 0)) (list-head* rest limit) rest)))

  (define (list-tail* l k) (if (or (null? l) (= k 0)) l (list-tail* (cdr l) (- k 1))))
  (define (list-head* l k) (if (or (null? l) (= k 0)) '() (cons (car l) (list-head* (cdr l) (- k 1)))))

  ;; ---- ORDER BY ----

  ;; Each term becomes (key-procedure descending? nulls-first?) where key-procedure takes the
  ;; table row and the result row (list of values).
  (define (compile-order-terms terms items scope)
    (let ([n (length items)])
      (let loop ([terms terms] [i 1] [acc '()])
        (if (null? terms)
            (reverse acc)
            (let* ([t (car terms)]
                   [desc (order-term-descending? t)]
                   [nulls (order-term-nulls t)]
                   [key (compile-key (order-term-expr t) i n items scope)])
              (loop (cdr terms) (+ i 1)
                    (cons (list key desc (if nulls (eq? nulls 'first) (not desc))) acc)))))))

  (define (compile-key expr i n items scope)
    (let ([k (ordinal-of expr)])
      (cond
        [k (if (and (>= k 1) (<= k n))
               (lambda (row res) (list-ref res (- k 1)))
               (raise-sql-error
                (string-append (ordinal-name i) " ORDER BY term out of range - should be between 1 and "
                               (number->string n))))]
        [(and (eq? (car expr) 'col) (alias-index (name-lower (cadr expr)) items))
         => (lambda (j) (lambda (row res) (list-ref res j)))]
        [else (let ([f (compile-expr expr scope)]) (lambda (row res) (f row)))])))

  ;; k for an integer literal k or -k, else #f.
  (define (ordinal-of expr)
    (cond [(and (eq? (car expr) 'lit) (sql-integer? (cadr expr))) (cadr expr)]
          [(and (eq? (car expr) 'neg) (eq? (car (cadr expr)) 'lit) (sql-integer? (cadr (cadr expr))))
           (- (cadr (cadr expr)))]
          [else #f]))

  (define (alias-index lower items)
    (let loop ([items items] [j 0])
      (cond [(null? items) #f]
            [(and (cdar items) (string=? (name-lower (cdar items)) lower)) j]
            [else (loop (cdr items) (+ j 1))])))

  (define (ordinal-name i)
    (string-append
     (number->string i)
     (cond [(memv (mod i 100) '(11 12 13)) "th"]
           [(= (mod i 10) 1) "st"]
           [(= (mod i 10) 2) "nd"]
           [(= (mod i 10) 3) "rd"]
           [else "th"])))

  ;; Does row a sort strictly before row b? Rows are (result . keys).
  (define (sort-before? terms a b)
    (let loop ([terms terms] [ka (cdr a)] [kb (cdr b)])
      (if (null? terms)
          #f
          (let ([c (compare-term (car terms) (car ka) (car kb))])
            (cond [(< c 0) #t] [(> c 0) #f] [else (loop (cdr terms) (cdr ka) (cdr kb))])))))

  (define (compare-term term x y)
    (let ([desc (cadr term)] [nulls-first (caddr term)])
      (cond [(and (sql-null? x) (sql-null? y)) 0]
            [(sql-null? x) (if nulls-first -1 1)]
            [(sql-null? y) (if nulls-first 1 -1)]
            [else (let ([c (compare-values x y)]) (if desc (- c) c))]))))
