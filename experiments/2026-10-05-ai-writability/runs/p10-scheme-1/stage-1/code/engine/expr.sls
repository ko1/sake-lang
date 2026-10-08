;;; Compiling expressions (1.8 - 1.10). An expression is first compiled against a scope, which
;;; resolves every name (so name errors happen before any row is read), into a procedure taking
;;; the current row (a vector of values) and returning a value.
(library (engine expr)
  (export make-scope scope-columns scope-aliases no-row-scope
          compile-expr expr-affinity expand-name)
  (import (rnrs) (engine errors) (engine value) (engine arith) (engine ast) (engine catalog)
          (engine functions))

  ;; columns: vector of column; aliases: list of (lowercase-name . expression) naming result columns.
  (define-record-type scope (fields columns aliases))

  (define no-row-scope (make-scope (vector) '()))

  (define (column-scope sc) (make-scope (scope-columns sc) '()))

  ;; A name resolves to a column (its index) or to an alias (its expression); columns win.
  ;; Returns (values index-or-#f alias-expr-or-#f); raises "no such column".
  (define (expand-name sc nm)
    (let* ([cols (scope-columns sc)]
           [lower (name-lower nm)]
           [idx (let loop ([i 0])
                  (cond [(= i (vector-length cols)) #f]
                        [(string=? (column-lower (vector-ref cols i)) lower) i]
                        [else (loop (+ i 1))]))])
      (if idx
          (values idx #f)
          (let ([a (assoc lower (scope-aliases sc))])
            (if a
                (values #f (cdr a))
                (raise-sql-error (string-append "no such column: " (name-text nm))))))))

  ;; Affinity of an expression (1.9): the column's type for a column reference, else #f.
  (define (expr-affinity ast sc)
    (if (eq? (car ast) 'col)
        (let-values ([(idx alias) (expand-name sc (cadr ast))])
          (if idx
              (column-type (vector-ref (scope-columns sc) idx))
              (expr-affinity alias (column-scope sc))))
        #f))

  (define (compile-expr ast sc)
    (case (car ast)
      [(lit) (let ([v (cadr ast)]) (lambda (row) v))]
      [(col)
       (let-values ([(idx alias) (expand-name sc (cadr ast))])
         (if idx
             (lambda (row) (vector-ref row idx))
             (compile-expr alias (column-scope sc))))]
      [(neg) (let ([f (compile-expr (cadr ast) sc)]) (lambda (row) (sql-negate (f row))))]
      [(pos) (compile-expr (cadr ast) sc)]
      [(not) (let ([f (compile-expr (cadr ast) sc)])
               (lambda (row) (truth->value (let ([t (truth (f row))]) (if (eq? t 'null) t (not t))))))]
      [(binop) (compile-binop (cadr ast) (caddr ast) (cadddr ast) sc)]
      [(call) (compile-call (cadr ast) (caddr ast) sc)]
      [else (error 'compile-expr "unknown expression" ast)]))

  ;; Truth value ('null, #t, #f) to a SQL value.
  (define (truth->value t) (if (eq? t 'null) sql-null (bool->value t)))

  (define (compile-binop op l r sc)
    (let ([fl (compile-expr l sc)] [fr (compile-expr r sc)])
      (case op
        [(plus minus times divide modulo)
         (lambda (row) (let* ([x (fl row)] [y (fr row)]) (sql-arith op x y)))]
        [(concat) (lambda (row) (let* ([x (fl row)] [y (fr row)]) (sql-concat x y)))]
        [(and)
         (lambda (row)
           (let ([a (truth (fl row))])
             (if (eq? a #f)
                 0
                 (let ([b (truth (fr row))])
                   (cond [(eq? b #f) 0] [(or (eq? a 'null) (eq? b 'null)) sql-null] [else 1])))))]
        [(or)
         (lambda (row)
           (let ([a (truth (fl row))])
             (if (eq? a #t)
                 1
                 (let ([b (truth (fr row))])
                   (cond [(eq? b #t) 1] [(or (eq? a 'null) (eq? b 'null)) sql-null] [else 0])))))]
        [else (compile-comparison op l r fl fr sc)])))

  (define (compile-comparison op l r fl fr sc)
    (let ([al (expr-affinity l sc)] [ar (expr-affinity r sc)])
      (define (compare row)
        (let* ([x (fl row)] [y (fr row)])
          (cond [(or (sql-null? x) (sql-null? y)) (values x y #f)]
                [else (let-values ([(x2 y2) (apply-affinity x al y ar)])
                        (values x2 y2 #t))])))
      (case op
        [(is isnot)
         (lambda (row)
           (let-values ([(x y both) (compare row)])
             (let ([same (if both
                             (= 0 (compare-values x y))
                             (and (sql-null? x) (sql-null? y)))])
               (bool->value (if (eq? op 'is) same (not same))))))]
        [else
         (let ([test (case op
                       [(eq) (lambda (c) (= c 0))] [(ne) (lambda (c) (not (= c 0)))]
                       [(lt) (lambda (c) (< c 0))] [(le) (lambda (c) (<= c 0))]
                       [(gt) (lambda (c) (> c 0))] [else (lambda (c) (>= c 0))])])
           (lambda (row)
             (let-values ([(x y both) (compare row)])
               (if both (bool->value (test (compare-values x y))) sql-null))))])))

  (define (compile-call nm args sc)
    (let ([fn (find-function (name-lower nm))])
      (unless fn (raise-sql-error (string-append "no such function: " (name-text nm))))
      (let ([n (length args)])
        (when (or (< n (function-min-args fn))
                  (and (function-max-args fn) (> n (function-max-args fn))))
          (raise-sql-error
           (string-append "wrong number of arguments to function " (name-text nm) "()"))))
      (let ([fs (map (lambda (a) (compile-expr a sc)) args)] [proc (function-proc fn)])
        (lambda (row) (apply proc (map (lambda (f) (f row)) fs)))))))
