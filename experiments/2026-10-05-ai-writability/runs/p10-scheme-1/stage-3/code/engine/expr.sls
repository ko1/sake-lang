;;; Compiling expressions (1.8 - 1.10). An expression is first compiled against a scope, which
;;; resolves every name (so name errors happen before any row is read), into a procedure taking
;;; the current row (a vector of values) and returning a value.
(library (engine expr)
  (export make-scope make-aggregate-scope make-misuse-scope scope-columns scope-aliases
          no-row-scope compile-expr expr-affinity expand-name)
  (import (rnrs) (engine errors) (engine value) (engine arith) (engine ast) (engine catalog)
          (engine functions) (engine strings) (engine cast) (engine aggregate))

;; columns: vector of column; aliases: list of (lowercase-name . expression) naming result columns.
  ;; aggregates: a collector (aggregate calls are allowed and gathered; they are evaluated on the
  ;; group's row followed by one value per aggregate), or a misuse (aggregate calls are errors).
  (define-record-type (scope new-scope scope?) (fields columns aliases aggregates))

  ;; direct / via-alias: procedures from an aggregate's name to the error message.
  (define-record-type misuse (fields direct via-alias))

  (define where-misuse
    (make-misuse (lambda (n) (string-append "misuse of aggregate function " n "()"))
                 (lambda (n) (string-append "misuse of aggregate: " n "()"))))

  ;; A scope in which aggregate calls are the error of WHERE (1.7, 3.3).
  (define (make-scope columns aliases) (new-scope columns aliases where-misuse))

  (define (make-misuse-scope columns aliases direct via-alias)
    (new-scope columns aliases (make-misuse direct via-alias)))

  (define (make-aggregate-scope columns aliases collector) (new-scope columns aliases collector))

  (define no-row-scope (make-scope (vector) '()))

  (define (column-scope sc) (new-scope (scope-columns sc) '() (scope-aggregates sc)))

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

  ;; A name standing for an aggregate call is an error where aggregates are not allowed.
  (define (check-alias-misuse alias sc)
    (let ([agg (scope-aggregates sc)])
      (when (misuse? agg)
        (let ([n (find-aggregate alias)])
          (when n (raise-sql-error ((misuse-via-alias agg) n)))))))

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
             (begin
               (check-alias-misuse alias sc)
               (compile-expr alias (column-scope sc)))))]
      [(neg) (let ([f (compile-expr (cadr ast) sc)]) (lambda (row) (sql-negate (f row))))]
      [(pos) (compile-expr (cadr ast) sc)]
      [(not) (let ([f (compile-expr (cadr ast) sc)])
               (lambda (row) (truth->value (let ([t (truth (f row))]) (if (eq? t 'null) t (not t))))))]
      [(binop) (compile-binop (cadr ast) (caddr ast) (cadddr ast) sc)]
      [(call) (compile-call ast sc)]
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

  ;; (call name args distinct? order star?)
  (define (compile-call ast sc)
    (let* ([nm (cadr ast)] [args (caddr ast)] [distinct? (cadddr ast)]
           [order (list-ref ast 4)] [star? (list-ref ast 5)]
           [lower (name-lower nm)]
           [kind (aggregate-kind lower (length args) star?)])
      (cond
        [kind (compile-aggregate nm kind args distinct? order sc)]
        [(find-function lower)
         => (lambda (fn) (compile-scalar-call nm fn args sc))]
        [(aggregate-name? lower) (raise-arity-error nm)]
        [else (raise-sql-error (string-append "no such function: " (name-text nm)))])))

  (define (raise-arity-error nm)
    (raise-sql-error (string-append "wrong number of arguments to function " (name-text nm) "()")))

  (define (compile-scalar-call nm fn args sc)
    (let ([n (length args)])
      (when (or (< n (function-min-args fn))
                (and (function-max-args fn) (> n (function-max-args fn))))
        (raise-arity-error nm)))
    (let ([fs (map (lambda (a) (compile-expr a sc)) args)] [proc (function-proc fn)])
      (lambda (row) (apply proc (map (lambda (f) (f row)) fs)))))

  ;; An aggregate call becomes a read of its slot, after the group's row (see make-scope above).
  (define (compile-aggregate nm kind args distinct? order sc)
    (let ([agg (scope-aggregates sc)])
      (when (misuse? agg) (raise-sql-error ((misuse-direct agg) (name-text nm))))
      (when (and distinct? (eq? kind 'group-concat) (> (length args) 1))
        (raise-sql-error "DISTINCT aggregates must have exactly one argument"))
      (let* ([row-scope (make-scope (scope-columns sc) '())]
             [arg-procs (map (lambda (a) (compile-expr a row-scope)) args)]
             [order-procs (map (lambda (t)
                                 (list (compile-expr (order-term-expr t) row-scope)
                                       (order-term-descending? t)
                                       (if (order-term-nulls t)
                                           (eq? (order-term-nulls t) 'first)
                                           (not (order-term-descending? t)))))
                               order)]
             [spec (make-agg-spec kind distinct?
                                  (if (eq? kind 'count-star) '() arg-procs)
                                  order-procs)]
             [slot (+ (vector-length (scope-columns sc))
                      (collector-register! agg (list (name-lower nm) (ast-key args) distinct?
                                                     (ast-key (map order-term->list order)))
                                           spec))])
        (lambda (row) (vector-ref row slot)))))

  (define (order-term->list t)
    (list (order-term-expr t) (order-term-descending? t) (order-term-nulls t)))

  ;; The expression with names replaced by their text, comparable with equal?.
  (define (ast-key x)
    (cond [(name? x) (name-lower x)]
          [(pair? x) (cons (ast-key (car x)) (ast-key (cdr x)))]
          [else x])))
