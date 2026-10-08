;;; Compiling expressions (1.8 - 1.10). An expression is first compiled against a scope, which
;;; resolves every name (so name errors happen before any row is read), into a procedure taking
;;; the current row (a vector of values) and returning a value.
(library (engine expr)
  (export make-scope scope-columns scope-aliases no-row-scope
          compile-expr expr-affinity expand-name)
  (import (rnrs) (engine errors) (engine value) (engine arith) (engine ast) (engine catalog)
          (engine functions) (engine strings) (engine cast))

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
    (case (car ast)
      [(col)
       (let-values ([(idx alias) (expand-name sc (cadr ast))])
         (if idx
             (column-type (vector-ref (scope-columns sc) idx))
             (expr-affinity alias (column-scope sc))))]
      [(cast) (caddr ast)]
      [else #f]))

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
      [(case) (compile-case (cadr ast) (caddr ast) (cadddr ast) sc)]
      [(between) (apply compile-between sc (cdr ast))]
      [(in) (apply compile-in sc (cdr ast))]
      [(like) (apply compile-like sc (cdr ast))]
      [(cast) (let ([f (compile-expr (cadr ast) sc)] [type (caddr ast)])
                (lambda (row) (sql-cast (f row) type)))]
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
      (case op
        [(is isnot)
         (lambda (row)
           (let* ([x (fl row)] [y (fr row)]
                  [same (if (or (sql-null? x) (sql-null? y))
                            (and (sql-null? x) (sql-null? y))
                            (= 0 (compare-with-affinity x al y ar)))])
             (bool->value (if (eq? op 'is) same (not same)))))]
        [else
         (let ([test (case op
                       [(eq) (lambda (c) (= c 0))] [(ne) (lambda (c) (not (= c 0)))]
                       [(lt) (lambda (c) (< c 0))] [(le) (lambda (c) (<= c 0))]
                       [(gt) (lambda (c) (> c 0))] [else (lambda (c) (>= c 0))])])
           (lambda (row)
             (let ([c (compare-with-affinity (fl row) al (fr row) ar)])
               (if c (bool->value (test c)) sql-null))))])))

  ;; Three-valued AND of truth values ('null, #t, #f).
  (define (truth-and a b)
    (cond [(or (eq? a #f) (eq? b #f)) #f] [(or (eq? a 'null) (eq? b 'null)) 'null] [else #t]))

  ;; CASE (2.3). operand is #f for the searched form; whens is a list of (test . result) ASTs.
  (define (compile-case operand whens else-expr sc)
    (let* ([fo (and operand (compile-expr operand sc))]
           [ao (and operand (expr-affinity operand sc))]
           [tests (map (lambda (w)
                         (let ([ft (compile-expr (car w) sc)] [fr (compile-expr (cdr w) sc)])
                           (if operand
                               (let ([at (expr-affinity (car w) sc)])
                                 (cons (lambda (row x) (eqv? 0 (compare-with-affinity x ao (ft row) at))) fr))
                               (cons (lambda (row x) (eq? #t (truth (ft row)))) fr))))
                       whens)]
           [fe (and else-expr (compile-expr else-expr sc))])
      (lambda (row)
        (let ([x (and fo (fo row))])
          (let loop ([ts tests])
            (cond [(null? ts) (if fe (fe row) sql-null)]
                  [((caar ts) row x) ((cdar ts) row)]
                  [else (loop (cdr ts))]))))))

  (define (negate-truth negated t)
    (truth->value (if (and negated (not (eq? t 'null))) (not t) t)))

  (define (compile-between sc x low high negated)
    (let ([fx (compile-expr x sc)] [fl (compile-expr low sc)] [fh (compile-expr high sc)]
          [ax (expr-affinity x sc)] [al (expr-affinity low sc)] [ah (expr-affinity high sc)])
      (lambda (row)
        (let* ([v (fx row)]
               [lo (compare-with-affinity v ax (fl row) al)]
               [hi (compare-with-affinity v ax (fh row) ah)]
               [t (truth-and (if lo (>= lo 0) 'null) (if hi (<= hi 0) 'null))])
          (negate-truth negated t)))))

  ;; IN (2.3): only x's affinity counts; each item is converted to it.
  (define (compile-in sc x items negated)
    (let ([fx (compile-expr x sc)] [ax (expr-affinity x sc)]
          [fs (map (lambda (e) (compile-expr e sc)) items)])
      (lambda (row)
        (let ([v (fx row)])
          (if (sql-null? v)
              sql-null
              (let loop ([fs fs] [seen-null #f])
                (if (null? fs)
                    (negate-truth negated (if seen-null 'null #f))
                    (let ([item (coerce-to-affinity-unless-null ((car fs) row) ax)])
                      (cond [(sql-null? item) (loop (cdr fs) #t)]
                            [(= 0 (compare-values v item)) (negate-truth negated #t)]
                            [else (loop (cdr fs) seen-null)])))))))))

  (define (coerce-to-affinity-unless-null v a)
    (if (sql-null? v) v (coerce-to-affinity v a)))

  (define (compile-like sc x pattern negated)
    (let ([fx (compile-expr x sc)] [fp (compile-expr pattern sc)])
      (lambda (row)
        (let ([v (fx row)] [p (fp row)])
          (if (or (sql-null? v) (sql-null? p))
              sql-null
              (negate-truth negated (text-like? (text-form v) (text-form p))))))))

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
