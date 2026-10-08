;;; ORDER BY, LIMIT and OFFSET (1.7): compiling ordering terms, sorting, and taking the window.
(library (engine orderby)
  (export compile-order-terms compile-compound-order-terms compile-bound sort-produced take-window
          ordinal-of ordinal-name alias-index)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine expr))

  ;; Each term becomes (key-procedure descending? nulls-first? collation) where key-procedure takes
  ;; the evaluation row and the result row (list of values). items: (expression . alias-or-#f)
  ;; pairs. A term may be followed by COLLATE (7.4); the collation of a term that stands for a
  ;; result column is that column's expression's.
  (define (compile-order-terms terms items scope)
    (let ([n (length items)])
      (let loop ([terms terms] [i 1] [acc '()])
        (if (null? terms)
            (reverse acc)
            (let* ([t (car terms)]
                   [desc (order-term-descending? t)]
                   [nulls (order-term-nulls t)]
                   [written (order-term-expr t)]
                   [explicit (and (eq? (car written) 'collate) (collation-by-name (caddr written)))]
                   [expr (if explicit (cadr written) written)]
                   [key (compile-key expr i n items scope)]
                   [coll (or explicit (key-collation expr items scope))])
              (loop (cdr terms) (+ i 1)
                    (cons (list key desc (if nulls (eq? nulls 'first) (not desc)) coll) acc)))))))

  ;; The collation of an ORDER BY term without COLLATE: that of the result column it stands for, or
  ;; of its expression.
  (define (key-collation expr items scope)
    (let* ([k (ordinal-of expr)]
           [j (and (not k) (eq? (car expr) 'col) (alias-index (name-lower (cadr expr)) items))]
           [e (cond [k (car (list-ref items (- k 1)))]
                    [j (car (list-ref items j))]
                    [else expr])])
      (single-collation e scope)))

  ;; The ORDER BY terms of a compound select (5.1): each is a column number or the name of a result
  ;; column of one of the simple-selects (part-columns: their column vectors, left to right).
  ;; Same shape as compile-order-terms; a term without COLLATE has the collation of its column of
  ;; the compound (7.4).
  (define (compile-compound-order-terms terms part-columns)
    (let ([n (vector-length (car part-columns))] [colls (compound-collations part-columns)])
      (let loop ([terms terms] [i 1] [acc '()])
        (if (null? terms)
            (reverse acc)
            (let* ([t (car terms)]
                   [desc (order-term-descending? t)]
                   [nulls (order-term-nulls t)]
                   [written (order-term-expr t)]
                   [explicit (and (eq? (car written) 'collate) (collation-by-name (caddr written)))]
                   [j (compound-term-column (if explicit (cadr written) written) i n part-columns)])
              (loop (cdr terms) (+ i 1)
                    (cons (list (lambda (row res) (list-ref res j)) desc
                                (if nulls (eq? nulls 'first) (not desc))
                                (or explicit (list-ref colls j)))
                          acc)))))))

  ;; Index of the result column an ORDER BY term of a compound select stands for.
  (define (compound-term-column expr i n part-columns)
    (let ([k (ordinal-of expr)])
      (cond
        [k (if (and (>= k 1) (<= k n))
               (- k 1)
               (raise-sql-error
                (string-append (ordinal-name i) " ORDER BY term out of range - should be between 1 and "
                               (number->string n))))]
        [(and (eq? (car expr) 'col)
              (let ([lower (name-lower (cadr expr))])
                (let scan ([parts part-columns])
                  (and (pair? parts)
                       (or (find-column-index (car parts) lower) (scan (cdr parts)))))))
         => values]
        [else (raise-sql-error (string-append (ordinal-name i)
                                              " ORDER BY term does not match any column in the result set"))])))

  (define (find-column-index cols lower)
    (let loop ([j 0])
      (cond [(= j (vector-length cols)) #f]
            [(string=? (column-lower (vector-ref cols j)) lower) j]
            [else (loop (+ j 1))])))

  ;; LIMIT / OFFSET: an expression evaluated with no row. Returns #f when absent, else a thunk
  ;; giving an integer, or #f for NULL.
  (define (compile-bound expr scope)
    (and expr
         (let ([f (compile-expr expr scope)])
           (lambda ()
             (let ([v (f (vector))])
               (cond [(sql-null? v) #f]
                     [else (let ([n (to-number v)]) (if (flonum? n) (exact (truncate n)) n))]))))))

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

  ;; 1st, 2nd, 3rd, 4th, ... 11th, 12th, 13th, 21st.
  (define (ordinal-name i)
    (string-append
     (number->string i)
     (cond [(memv (mod i 100) '(11 12 13)) "th"]
           [(= (mod i 10) 1) "st"]
           [(= (mod i 10) 2) "nd"]
           [(= (mod i 10) 3) "rd"]
           [else "th"])))

  ;; produced: list of (result . keys), keys computed by the compiled terms. A stable sort.
  (define (sort-produced terms produced)
    (if (null? terms)
        produced
        (list-sort (lambda (a b) (sort-before? terms a b)) produced)))

  (define (sort-before? terms a b)
    (let loop ([terms terms] [ka (cdr a)] [kb (cdr b)])
      (if (null? terms)
          #f
          (let ([c (compare-for-sort (car ka) (car kb) (cadar terms) (caddar terms) (cadddr (car terms)))])
            (cond [(< c 0) #t] [(> c 0) #f] [else (loop (cdr terms) (cdr ka) (cdr kb))])))))

  ;; Skips offset rows (#f or <= 0: none), then keeps at most limit rows (#f or negative: all).
  (define (take-window rows offset limit)
    (let ([rest (if (and offset (> offset 0)) (list-tail* rows offset) rows)])
      (if (and limit (>= limit 0)) (list-head* rest limit) rest)))

  (define (list-tail* l k) (if (or (null? l) (= k 0)) l (list-tail* (cdr l) (- k 1))))
  (define (list-head* l k) (if (or (null? l) (= k 0)) '() (cons (car l) (list-head* (cdr l) (- k 1))))))
