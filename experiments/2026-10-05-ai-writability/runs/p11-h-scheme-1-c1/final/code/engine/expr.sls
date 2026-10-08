;;; Compiling expressions (1.8 - 1.10, 4.3). An expression is first compiled against a scope, which
;;; resolves every name (so name errors happen before any row is read), into a procedure taking
;;; the current row (a vector of values) and returning a value.
(library (engine expr)
  (export compile-expr expr-affinity expr-collation single-collation install-subquery-planner!)
  (import (rnrs) (only (chezscheme) unbox set-box!) (engine errors) (engine value) (engine arith)
          (engine ast) (engine catalog) (engine scope) (engine functions) (engine strings)
          (engine cast) (engine aggregate) (engine window))

  ;; This library cannot import the SELECT executor (which imports this one), so the executor
  ;; installs itself here. A planner takes (database select-stmt link) and returns two values: the
  ;; vector of result columns and a thunk giving the result rows (lists of values).
  (define subquery-planner #f)
  (define (install-subquery-planner! planner) (set! subquery-planner planner))

  (define (column-scope sc) (scope-with-aliases sc '()))

  ;; ---- names ----

  ;; The procedure reading what a lookup-name answer stands for, from the row of the query whose
  ;; scope is sc.
  (define (compile-found sc found)
    (case (car found)
      [(slot) (let ([idx (cadr found)]) (lambda (row) (vector-ref row idx)))]
      [(alias)
       (check-alias-misuse (cadr found) (caddr found) sc)
       (compile-expr (cadr found) (column-scope sc))]
      [else
       (let ([link (cadr found)])
         (link-mark-used! link)
         (let ([f (compile-found (link-scope link) (caddr found))])
           (lambda (row) (f (unbox (link-box link))))))]))

  (define (found-affinity sc found)
    (case (car found)
      [(slot) (column-type (caddr found))]
      [(alias) (expr-affinity (cadr found) (column-scope sc))]
      [else (found-affinity (link-scope (cadr found)) (caddr found))]))

  ;; A name standing for an aggregate call is an error where aggregates are not allowed.
  ;; expr: the aliased expression; text: the alias as written.
  (define (check-alias-misuse expr text sc)
    (let ([agg (scope-aggregates sc)])
      (when (misuse? agg)
        (let ([n (find-aggregate expr)])
          (when n (raise-sql-error ((misuse-via-alias agg) n)))))
      (unless (scope-windows sc)
        (when (find-call window-call? expr)
          (raise-sql-error (string-append "misuse of aliased window function " text))))))

  ;; A call with OVER (6.1).
  (define (window-call? call) (and (list-ref call 6) #t))

  ;; Affinity of an expression (1.9): the column's type for a column reference, else #f.
  (define (expr-affinity ast sc)
    (case (car ast)
      [(col) (found-affinity sc (resolve-name sc #f (cadr ast)))]
      [(qcol) (found-affinity sc (resolve-name sc (cadr ast) (caddr ast)))]
      [(slot) (column-type (caddr ast))]
      [(cast) (caddr ast)]
      [(collate) (expr-affinity (cadr ast) sc)]
      [(subquery)
       (let-values ([(cols run) (prepare-subquery sc (cadr ast))])
         (and (= (vector-length cols) 1) (column-type (vector-ref cols 0))))]
      [else #f]))

  ;; ---- collations (7.3, 7.4) ----

  ;; The collation of a lookup-name answer: (collation . explicit?), or #f for none.
  (define (found-collation sc found)
    (case (car found)
      [(slot) (cons (or (column-collation (caddr found)) 'binary) #f)]
      [(alias) (expr-collation (cadr found) (column-scope sc))]
      [else (found-collation (link-scope (cadr found)) (caddr found))]))

  ;; The collation of an expression (7.3): (collation . explicit?), or #f for none.
  (define (expr-collation ast sc)
    (case (car ast)
      [(col) (found-collation sc (resolve-name sc #f (cadr ast)))]
      [(qcol) (found-collation sc (resolve-name sc (cadr ast) (caddr ast)))]
      [(slot) (cons (or (column-collation (caddr ast)) 'binary) #f)]
      [(collate) (cons (collation-by-name (caddr ast)) #t)]
      [(pos cast) (expr-collation (cadr ast) sc)]
      [else #f]))

  ;; The collation used to compare two operands a and b with collations ca, cb (7.4).
  (define (combine-collations ca cb)
    (cond [(and ca (cdr ca)) (car ca)]
          [(and cb (cdr cb)) (car cb)]
          [ca (car ca)]
          [cb (car cb)]
          [else 'binary]))

  (define (pair-collation a b sc) (combine-collations (expr-collation a sc) (expr-collation b sc)))

  ;; The collation for comparing the values of one expression among themselves (7.4).
  (define (single-collation ast sc)
    (let ([c (expr-collation ast sc)]) (if c (car c) 'binary)))

  ;; The (collation . explicit?) of a result column of a subquery, or #f.
  (define (column-collation-of col)
    (and (column-collation col) (cons (column-collation col) (column-explicit-collation? col))))

  ;; ---- subqueries (4.3) ----

  ;; Returns the result columns and a procedure from the current row to the subquery's rows. A
  ;; subquery that does not refer to the enclosing query runs once.
  (define (prepare-subquery sc stmt)
    (let ([link (make-link sc)])
      (let-values ([(cols run) (subquery-planner (scope-db sc) stmt link)])
        (values cols
                (if (link-used? link)
                    (lambda (row) (set-box! (link-box link) row) (run))
                    (let ([cache #f])
                      (lambda (row) (or cache (begin (set! cache (run)) cache)))))))))

  (define (expect-one-column cols compared?)
    (let ([n (vector-length cols)])
      (unless (= n 1)
        (raise-sql-error
         (if compared?
             "row value misused"
             (string-append "sub-select returns " (number->string n) " columns - expected 1"))))))

  ;; compared?: the subquery is a direct operand of a comparison (so a row value is misused).
  (define (compile-scalar-subquery sc stmt compared?)
    (let-values ([(cols rows-of) (prepare-subquery sc stmt)])
      (expect-one-column cols compared?)
      (lambda (row)
        (let ([rows (rows-of row)])
          (if (null? rows) sql-null (car (car rows)))))))

  (define (compile-exists sc stmt)
    (let-values ([(cols rows-of) (prepare-subquery sc stmt)])
      (lambda (row) (bool->value (pair? (rows-of row))))))

  ;; x IN (select): the values are compared with x as `x = v`, v with its column's affinity and
  ;; collation.
  (define (compile-in-subquery sc x stmt negated)
    (let ([fx (compile-expr x sc)] [ax (expr-affinity x sc)])
      (let-values ([(cols rows-of) (prepare-subquery sc stmt)])
        (expect-one-column cols #f)
        (let ([av (column-type (vector-ref cols 0))]
              [coll (combine-collations (expr-collation x sc) (column-collation-of (vector-ref cols 0)))])
          (lambda (row)
            (let ([v (fx row)] [rows (rows-of row)])
              (cond
                [(null? rows) (negate-truth negated #f)]
                [(sql-null? v) sql-null]
                [else
                 (let loop ([rows rows] [seen-null #f])
                   (if (null? rows)
                       (negate-truth negated (if seen-null 'null #f))
                       (let ([item (car (car rows))])
                         (cond [(sql-null? item) (loop (cdr rows) #t)]
                               [(eqv? 0 (compare-with-affinity v ax item av coll)) (negate-truth negated #t)]
                               [else (loop (cdr rows) seen-null)]))))])))))))

  ;; An operand of a comparison, BETWEEN or CASE x: a subquery there must have one column, and says
  ;; `row value misused` otherwise. `IS NULL` / `IS NOT NULL` (other is the literal NULL) do not count.
  (define (compile-compared ast other sc)
    (if (and (eq? (car ast) 'subquery) (not (equal? other '(lit null))))
        (compile-scalar-subquery sc (cadr ast) #t)
        (compile-expr ast sc)))

  (define (compile-expr ast sc)
    (case (car ast)
      [(lit) (let ([v (cadr ast)]) (lambda (row) v))]
      [(col) (compile-found sc (resolve-name sc #f (cadr ast)))]
      [(qcol) (compile-found sc (resolve-name sc (cadr ast) (caddr ast)))]
      [(slot) (let ([idx (cadr ast)]) (lambda (row) (vector-ref row idx)))]
      [(subquery) (compile-scalar-subquery sc (cadr ast) #f)]
      [(exists) (compile-exists sc (cadr ast))]
      [(insub) (compile-in-subquery sc (cadr ast) (caddr ast) (cadddr ast))]
      [(neg) (let ([f (compile-expr (cadr ast) sc)]) (lambda (row) (sql-negate (f row))))]
      [(pos) (compile-expr (cadr ast) sc)]
      [(collate) (collation-by-name (caddr ast)) (compile-expr (cadr ast) sc)]
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
    (let* ([comparison? (memq op '(eq ne lt le gt ge is isnot))]
           [fl (if comparison? (compile-compared l r sc) (compile-expr l sc))]
           [fr (if comparison? (compile-compared r l sc) (compile-expr r sc))])
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
    (let ([al (expr-affinity l sc)] [ar (expr-affinity r sc)] [coll (pair-collation l r sc)])
      (case op
        [(is isnot)
         (lambda (row)
           (let* ([x (fl row)] [y (fr row)]
                  [same (if (or (sql-null? x) (sql-null? y))
                            (and (sql-null? x) (sql-null? y))
                            (= 0 (compare-with-affinity x al y ar coll)))])
             (bool->value (if (eq? op 'is) same (not same)))))]
        [else
         (let ([test (case op
                       [(eq) (lambda (c) (= c 0))] [(ne) (lambda (c) (not (= c 0)))]
                       [(lt) (lambda (c) (< c 0))] [(le) (lambda (c) (<= c 0))]
                       [(gt) (lambda (c) (> c 0))] [else (lambda (c) (>= c 0))])])
           (lambda (row)
             (let ([c (compare-with-affinity (fl row) al (fr row) ar coll)])
               (if c (bool->value (test c)) sql-null))))])))

  ;; Three-valued AND of truth values ('null, #t, #f).
  (define (truth-and a b)
    (cond [(or (eq? a #f) (eq? b #f)) #f] [(or (eq? a 'null) (eq? b 'null)) 'null] [else #t]))

  ;; CASE (2.3). operand is #f for the searched form; whens is a list of (test . result) ASTs.
  (define (compile-case operand whens else-expr sc)
    (let* ([fo (and operand (compile-compared operand '(none) sc))]
           [ao (and operand (expr-affinity operand sc))]
           [tests (map (lambda (w)
                         (let ([ft (compile-expr (car w) sc)] [fr (compile-expr (cdr w) sc)])
                           (if operand
                               (let ([at (expr-affinity (car w) sc)]
                                     [coll (pair-collation operand (car w) sc)])
                                 (cons (lambda (row x) (eqv? 0 (compare-with-affinity x ao (ft row) at coll))) fr))
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
    (let ([fx (compile-compared x '(none) sc)] [fl (compile-compared low '(none) sc)]
          [fh (compile-compared high '(none) sc)]
          [ax (expr-affinity x sc)] [al (expr-affinity low sc)] [ah (expr-affinity high sc)]
          [cl (pair-collation x low sc)] [ch (pair-collation x high sc)])
      (lambda (row)
        (let* ([v (fx row)]
               [lo (compare-with-affinity v ax (fl row) al cl)]
               [hi (compare-with-affinity v ax (fh row) ah ch)]
               [t (truth-and (if lo (>= lo 0) 'null) (if hi (<= hi 0) 'null))])
          (negate-truth negated t)))))

  ;; IN (2.3): only x's affinity and collation count; each item is converted to the affinity.
  (define (compile-in sc x items negated)
    (let ([fx (compile-expr x sc)] [ax (expr-affinity x sc)] [coll (single-collation x sc)]
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
                            [(= 0 (compare-values v item coll)) (negate-truth negated #t)]
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
           [over (list-ref ast 6)]
           [kind (aggregate-kind lower (length args) star?)])
      (cond
        [over (compile-window-call nm lower args star? over sc)]
        [kind (compile-aggregate nm kind args distinct? order sc)]
        [(find-function lower)
         => (lambda (fn) (compile-scalar-call nm fn args sc))]
        [(aggregate-name? lower) (raise-arity-error nm)]
        [(window-function-name? lower) (raise-window-misuse nm)]
        [else (raise-sql-error (string-append "no such function: " (name-text nm)))])))

  (define (raise-window-misuse nm)
    (raise-sql-error (string-append "misuse of window function " (name-text nm) "()")))

  (define (raise-arity-error nm)
    (raise-sql-error (string-append "wrong number of arguments to function " (name-text nm) "()")))

  (define (compile-scalar-call nm fn args sc)
    (let ([n (length args)])
      (when (or (< n (function-min-args fn))
                (and (function-max-args fn) (> n (function-max-args fn))))
        (raise-arity-error nm)))
    (let ([fs (map (lambda (a) (compile-expr a sc)) args)] [proc (function-proc fn)])
      (lambda (row) (apply proc (map (lambda (f) (f row)) fs)))))

  ;; An aggregate call becomes a read of its slot, after the group's row (see aggregate-scope in select.sls).
  (define (compile-aggregate nm kind args distinct? order sc)
    (let ([agg (scope-aggregates sc)])
      (when (misuse? agg) (raise-sql-error ((misuse-direct agg) (name-text nm))))
      (when (and distinct? (eq? kind 'group-concat) (> (length args) 1))
        (raise-sql-error "DISTINCT aggregates must have exactly one argument"))
      (let* ([row-scope (scope-for-rows sc)]
             [arg-procs (map (lambda (a) (compile-expr a row-scope)) args)]
             [order-procs (map (lambda (t)
                                 (list (compile-expr (order-term-expr t) row-scope)
                                       (order-term-descending? t)
                                       (if (order-term-nulls t)
                                           (eq? (order-term-nulls t) 'first)
                                           (not (order-term-descending? t)))
                                       (single-collation (order-term-expr t) row-scope)))
                               order)]
             [spec (make-agg-spec kind distinct?
                                  (if (eq? kind 'count-star) '() arg-procs)
                                  order-procs
                                  (if (and (pair? args) (not (eq? kind 'count-star)))
                                      (single-collation (car args) row-scope)
                                      'binary))]
             [slot (+ (scope-width sc)
                      (collector-register! agg (list (name-lower nm) (ast-key args) distinct?
                                                     (ast-key (map order-term->list order)))
                                           spec))])
        (lambda (row) (vector-ref row slot)))))

  ;; A window call (6.1 - 6.3) becomes a read of its slot, after the row and its aggregates (the base
  ;; of the window collector, set by the SELECT). Its expressions are over the same evaluation row.
  (define (compile-window-call nm lower args star? over sc)
    (let ([wc (scope-windows sc)])
      (unless wc (raise-window-misuse nm))
      (let* ([kind (aggregate-kind lower (length args) star?)]
             [arity (window-function-arity lower)])
        (cond
          [kind #t]
          [arity (when (or (< (length args) (car arity)) (> (length args) (cdr arity)))
                   (raise-arity-error nm))]
          [(find-function lower)
           (raise-sql-error (string-append lower "() may not be used as a window function"))]
          [(aggregate-name? lower) (raise-arity-error nm)]
          [else (raise-sql-error (string-append "no such function: " (name-text nm)))])
        (let* ([spec (resolve-window over (scope-window-defs sc))]
               [inner (scope-with-aliases (scope-with-windows sc #f) '())]
               [partition (caddr spec)] [order (cadddr spec)] [frame (list-ref spec 4)])
          (check-frame frame (length order))
          (let* ([arg-procs (if (eq? kind 'count-star) '() (map (lambda (a) (compile-expr a inner)) args))]
                 [plan (make-wplan (if kind 'agg (string->symbol lower))
                                   (and kind (make-agg-spec kind #f arg-procs '()
                                                            (if (pair? args) (single-collation (car args) inner) 'binary)))
                                   arg-procs
                                   (map (lambda (e) (compile-expr e inner)) partition)
                                   (map (lambda (e) (single-collation e inner)) partition)
                                   (map (lambda (t)
                                          (list (compile-expr (order-term-expr t) inner)
                                                (order-term-descending? t)
                                                (if (order-term-nulls t)
                                                    (eq? (order-term-nulls t) 'first)
                                                    (not (order-term-descending? t)))
                                                (single-collation (order-term-expr t) inner)))
                                        order)
                                   frame)]
                 [index (window-collector-register!
                         wc (ast-key (list lower args star? partition (map order-term->list order) frame))
                         plan)])
            (lambda (row) (vector-ref row (+ (window-collector-base wc) index))))))))

  (define (order-term->list t)
    (list (order-term-expr t) (order-term-descending? t) (order-term-nulls t)))

  ;; The expression with names replaced by their text, comparable with equal?.
  (define (ast-key x)
    (cond [(name? x) (name-lower x)]
          [(pair? x) (cons (ast-key (car x)) (ast-key (cdr x)))]
          [else x])))
