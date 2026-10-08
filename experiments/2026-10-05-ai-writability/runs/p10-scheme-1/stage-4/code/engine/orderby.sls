;;; ORDER BY, LIMIT and OFFSET (1.7): compiling ordering terms, sorting, and taking the window.
(library (engine orderby)
  (export compile-order-terms sort-produced take-window ordinal-of ordinal-name alias-index)
  (import (rnrs) (engine errors) (engine ast) (engine value) (engine expr))

  ;; Each term becomes (key-procedure descending? nulls-first?) where key-procedure takes the
  ;; evaluation row and the result row (list of values). items: (expression . alias-or-#f) pairs.
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
          (let ([c (compare-for-sort (car ka) (car kb) (cadar terms) (caddar terms))])
            (cond [(< c 0) #t] [(> c 0) #f] [else (loop (cdr terms) (cdr ka) (cdr kb))])))))

  ;; Skips offset rows (#f or <= 0: none), then keeps at most limit rows (#f or negative: all).
  (define (take-window rows offset limit)
    (let ([rest (if (and offset (> offset 0)) (list-tail* rows offset) rows)])
      (if (and limit (>= limit 0)) (list-head* rest limit) rest)))

  (define (list-tail* l k) (if (or (null? l) (= k 0)) l (list-tail* (cdr l) (- k 1))))
  (define (list-head* l k) (if (or (null? l) (= k 0)) '() (cons (car l) (list-head* (cdr l) (- k 1))))))
