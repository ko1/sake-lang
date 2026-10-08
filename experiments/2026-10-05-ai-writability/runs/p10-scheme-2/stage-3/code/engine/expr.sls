;;; (engine expr) -- compiling an expression AST into a procedure of a row.
;;;
;;; Compiling resolves every name and function and checks argument counts, so
;;; all name errors happen before any row is read (spec 1.7).  A compiled
;;; expression is a `cexpr`: proc maps a row (vector of values) to a value;
;;; affinity is integer, real, text or #f (spec 1.9).
(library (engine expr)
  (export make-scope make-cexpr cexpr-proc cexpr-affinity compile-expr
          make-aggregate-collector collector-specs collector-take-used!
          aggregate-spec-aggregate aggregate-spec-star aggregate-spec-distinct
          aggregate-spec-args aggregate-spec-order
          misuse-in-where misuse-in-order-by misuse-in-group-by)
  (import (rnrs) (engine errors) (engine values) (engine ast)
          (engine catalog) (engine operators) (engine functions) (engine aggregates))

  (define-record-type cexpr (fields proc affinity))

  ;; Aggregate calls (spec 3.2).  An aggregate query compiles its expressions against a
  ;; `collector`, which numbers each distinct call; a call's value is then read from slot
  ;; ncols+number of the row the executor builds (see (engine aggregation)).  Elsewhere the
  ;; scope holds a procedure (written-name -> message) saying why aggregates are not allowed.
  (define-record-type aggregate-spec (fields aggregate name key star distinct args order))
  ;; args: argument procs; order: list of (order-term . proc), for group_concat(... ORDER BY ...).
  (define-record-type (aggregate-collector make-aggregate-collector* aggregate-collector?)
    (fields ncols (mutable specs) (mutable used)))

  (define (make-aggregate-collector ncols) (make-aggregate-collector* ncols '() '()))
  (define (collector-specs c) (aggregate-collector-specs c))
  ;; The written names of the aggregate calls compiled since the last take, in order.
  (define (collector-take-used! c)
    (let ([used (reverse (aggregate-collector-used c))])
      (aggregate-collector-used-set! c '())
      used))

  ;; The slot of the call with this key, registering `spec` if the key is new.
  (define (collector-register! c spec)
    (let loop ([specs (aggregate-collector-specs c)] [i 0])
      (cond [(null? specs)
             (aggregate-collector-specs-set! c (append (aggregate-collector-specs c) (list spec)))
             i]
            [(equal? (aggregate-spec-key (car specs)) (aggregate-spec-key spec)) i]
            [else (loop (cdr specs) (+ i 1))])))

  (define (misuse-in-where name) (string-append "misuse of aggregate function " name "()"))
  (define (misuse-in-order-by name) (string-append "misuse of aggregate: " name "()"))
  (define (misuse-in-group-by name) "aggregate functions are not allowed in the GROUP BY clause")

  ;; table: the table whose columns names refer to, or #f (no row in scope).
  ;; aliases: alist lower-cased alias -> (index . cexpr), tried after the columns; the cdr
  ;; may instead be a message string, which is the error a use of that alias raises.
  ;; aggregates: an aggregate-collector, or a procedure as described above.
  (define-record-type (scope make-scope* scope?) (fields table aliases aggregates))
  (define make-scope
    (case-lambda
      [(table aliases) (make-scope* table aliases misuse-in-where)]
      [(table aliases aggregates) (make-scope* table aliases aggregates)]))

  (define (constant v) (make-cexpr (lambda (row) v) #f))

  (define (resolve-column scope qualifier name)
    (let* ([tbl (scope-table scope)]
           [lname (ascii-downcase name)]
           [written (if qualifier (string-append qualifier "." name) name)]
           [qualifier-ok? (or (not qualifier) (and tbl (string=? (ascii-downcase qualifier)
                                                                  (ascii-downcase (table-name tbl)))))]
           [index (and tbl qualifier-ok? (table-find-column tbl lname))]
           [alias (and (not qualifier) (assoc lname (scope-aliases scope)))])
      (cond [index (make-cexpr (lambda (row) (vector-ref row index))
                               (column-type (vector-ref (table-columns tbl) index)))]
            [(and alias (string? (cddr alias))) (raise-sql-error (cddr alias))]
            [alias (cddr alias)]
            [else (raise-sql-error (string-append "no such column: " written))])))

  (define (wrong-argument-count name)
    (raise-sql-error (string-append "wrong number of arguments to function " name "()")))

  (define (compile-call scope name args distinct? order star?)
    (let ([lname (ascii-downcase name)])
      (if (aggregate-call? lname (length args))
          (compile-aggregate-call scope name lname args distinct? order star?)
          (compile-scalar-call scope name lname args))))

  (define (compile-scalar-call scope name lname args)
    (let ([fn (find-function lname)])
      (unless fn (raise-sql-error (string-append "no such function: " name)))
      (let ([n (length args)])
        (when (or (< n (function-min-args fn))
                  (and (function-max-args fn) (> n (function-max-args fn))))
          (wrong-argument-count name)))
      (let ([procs (map (lambda (a) (cexpr-proc (compile-expr a scope))) args)]
            [f (function-proc fn)])
        (make-cexpr (lambda (row) (f (map (lambda (p) (p row)) procs))) #f))))

  (define (compile-aggregate-call scope name lname args distinct? order star?)
    (let ([agg (find-aggregate lname)] [n (length args)] [collector (scope-aggregates scope)])
      (when (and distinct? (string=? lname "group_concat") (= n 2))
        (raise-sql-error "DISTINCT aggregates must have exactly one argument"))
      (when (if star?
                (not (string=? lname "count"))
                (or (< n (aggregate-min-args agg)) (> n (aggregate-max-args agg))))
        (wrong-argument-count name))
      (unless (aggregate-collector? collector) (raise-sql-error (collector name)))
      ;; arguments see columns only, and may not contain aggregates themselves
      (let* ([inner (make-scope (scope-table scope) '() misuse-in-where)]
             [arg-procs (map (lambda (a) (cexpr-proc (compile-expr a inner))) args)]
             [order-procs (map (lambda (t) (cons t (cexpr-proc (compile-expr (order-term-expr t) inner))))
                               order)]
             [key (list lname distinct? star? args
                        (map (lambda (t) (list (order-term-expr t) (order-term-direction t) (order-term-nulls t)))
                             order))]
             [slot (+ (aggregate-collector-ncols collector)
                      (collector-register! collector
                                           (make-aggregate-spec agg name key star? distinct? arg-procs order-procs)))])
        (aggregate-collector-used-set! collector (cons name (aggregate-collector-used collector)))
        (make-cexpr (lambda (row) (vector-ref row slot)) #f))))

    (define (lift2 f l r)
    (let ([lp (cexpr-proc l)] [rp (cexpr-proc r)])
      (make-cexpr (lambda (row) (f (lp row) (rp row))) #f)))

  ;; A comparison-like operator: `finish` takes the converted operand values.
  (define (compile-comparison finish l r)
    (let-values ([(lconv rconv) (comparison-converters (cexpr-affinity l) (cexpr-affinity r))])
      (let ([lp (cexpr-proc l)] [rp (cexpr-proc r)])
        (make-cexpr (lambda (row)
                      (let ([a (lp row)] [b (rp row)])
                        (finish (if lconv (lconv a) a) (if rconv (rconv b) b))))
                    #f))))

  ;; A binary operator applied to two compiled operands.
  (define (binary-cexpr op l r)
    (case op
      [(+) (lift2 op-add l r)] [(-) (lift2 op-sub l r)] [(*) (lift2 op-mul l r)]
      [(/) (lift2 op-div l r)] [(%) (lift2 op-mod l r)]
      [(concat) (lift2 op-concat l r)]
      [(and) (lift2 op-and l r)] [(or) (lift2 op-or l r)]
      [(=) (compile-comparison (lambda (a b) (op-compare zero? a b)) l r)]
      [(!=) (compile-comparison (lambda (a b) (op-compare (lambda (c) (not (zero? c))) a b)) l r)]
      [(<) (compile-comparison (lambda (a b) (op-compare negative? a b)) l r)]
      [(<=) (compile-comparison (lambda (a b) (op-compare (lambda (c) (<= c 0)) a b)) l r)]
      [(>) (compile-comparison (lambda (a b) (op-compare positive? a b)) l r)]
      [(>=) (compile-comparison (lambda (a b) (op-compare (lambda (c) (>= c 0)) a b)) l r)]
      [(is) (compile-comparison op-is l r)]
      [(is-not) (compile-comparison (lambda (a b) (op-not (op-is a b))) l r)]
      [else (error 'compile-expr "unknown operator" op)]))

  (define (compile-binary scope op left right)
    (binary-cexpr op (compile-expr left scope) (compile-expr right scope)))

  (define (negate-if negated? c)
    (if negated? (lift1 op-not c) c))

  (define (lift1 f c)
    (let ([p (cexpr-proc c)]) (make-cexpr (lambda (row) (f (p row))) #f)))

  ;; x BETWEEN low AND high  ==  x >= low AND x <= high
  (define (compile-between scope negated? x low high)
    (let ([x (compile-expr x scope)])
      (negate-if negated?
                 (binary-cexpr 'and
                               (binary-cexpr '>= x (compile-expr low scope))
                               (binary-cexpr '<= x (compile-expr high scope))))))

  ;; Only x's affinity counts: every item is converted to it.
  (define (compile-in scope negated? x items)
    (let* ([x (compile-expr x scope)]
           [xp (cexpr-proc x)]
           [convert (or (affinity-converter (cexpr-affinity x)) (lambda (v) v))]
           [procs (map (lambda (e) (cexpr-proc (compile-expr e scope))) items)])
      (negate-if negated?
                 (make-cexpr (lambda (row)
                               (op-in (xp row) (map (lambda (p) (convert (p row))) procs)))
                             #f))))

  (define (compile-like scope negated? x pattern)
    (negate-if negated? (lift2 op-like (compile-expr x scope) (compile-expr pattern scope))))

  (define (compile-cast scope x type)
    (let ([p (cexpr-proc (compile-expr x scope))])
      (make-cexpr (lambda (row) (cast-value type (p row))) type)))

  ;; whens: list of (condition . result); operand is #f for the searched form.
  (define (compile-case scope operand whens else-expr)
    (let* ([operand (and operand (compile-expr operand scope))]
           [tests (map (lambda (w)
                         (let ([c (compile-expr (car w) scope)])
                           (cexpr-proc (if operand (binary-cexpr '= operand c) c))))
                       whens)]
           [results (map (lambda (w) (cexpr-proc (compile-expr (cdr w) scope))) whens)]
           [else-proc (if else-expr
                          (cexpr-proc (compile-expr else-expr scope))
                          (lambda (row) sql-null))])
      (make-cexpr (lambda (row)
                    (let loop ([tests tests] [results results])
                      (cond [(null? tests) (else-proc row)]
                            [(eq? (truth ((car tests) row)) #t) ((car results) row)]
                            [else (loop (cdr tests) (cdr results))])))
                  #f)))

  (define (compile-unary f operand scope)
    (let ([p (cexpr-proc (compile-expr operand scope))])
      (make-cexpr (lambda (row) (f (p row))) #f)))

  (define (compile-expr ast scope)
    (case (car ast)
      [(lit) (constant (cadr ast))]
      [(col) (resolve-column scope (cadr ast) (caddr ast))]
      [(neg) (compile-unary op-neg (cadr ast) scope)]
      [(pos) (compile-unary op-pos (cadr ast) scope)]
      [(not) (compile-unary op-not (cadr ast) scope)]
      [(bin) (compile-binary scope (cadr ast) (caddr ast) (cadddr ast))]
      [(call) (apply compile-call scope (cdr ast))]
      [(case) (compile-case scope (cadr ast) (caddr ast) (cadddr ast))]
      [(between) (apply compile-between scope (cdr ast))]
      [(in) (apply compile-in scope (cdr ast))]
      [(like) (apply compile-like scope (cdr ast))]
      [(cast) (compile-cast scope (cadr ast) (caddr ast))]
      [else (error 'compile-expr "unknown expression" ast)])))
