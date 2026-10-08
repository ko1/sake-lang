;;; (engine ordering) -- ORDER BY terms: comparing sort keys and naming positions.
(library (engine ordering)
  (export compare-keys ordinal position-term)
  (import (rnrs) (engine values) (engine ast))

  ;; "1st", "2nd", "3rd", "4th", ... "11th", "21st"
  (define (ordinal n)
    (let ([suffix (cond [(memv (mod n 100) '(11 12 13)) "th"]
                        [(= (mod n 10) 1) "st"]
                        [(= (mod n 10) 2) "nd"]
                        [(= (mod n 10) 3) "rd"]
                        [else "th"])])
      (string-append (number->string n) suffix)))

  ;; -1/0/1 comparing two key lists under the order terms.
  (define (compare-keys terms a b)
    (let loop ([terms terms] [a a] [b b])
      (if (null? terms)
          0
          (let* ([term (car terms)]
                 [desc? (eq? (order-term-direction term) 'desc)]
                 [nulls-first? (case (order-term-nulls term) [(first) #t] [(last) #f] [else (not desc?)])]
                 [x (car a)] [y (car b)]
                 [c (cond [(and (sql-null? x) (sql-null? y)) 0]
                          [(sql-null? x) (if nulls-first? -1 1)]
                          [(sql-null? y) (if nulls-first? 1 -1)]
                          [desc? (- (value-compare x y))]
                          [else (value-compare x y)])])
            (if (zero? c) (loop (cdr terms) (cdr a) (cdr b)) c)))))

  ;; The k of an ORDER BY / GROUP BY term that is an integer literal (or minus one), else #f.
  (define (position-term expr)
    (cond [(and (eq? (car expr) 'lit) (integer-value? (cadr expr))) (cadr expr)]
          [(and (eq? (car expr) 'neg) (eq? (car (cadr expr)) 'lit) (integer-value? (cadr (cadr expr))))
           (- (cadr (cadr expr)))]
          [else #f])))
