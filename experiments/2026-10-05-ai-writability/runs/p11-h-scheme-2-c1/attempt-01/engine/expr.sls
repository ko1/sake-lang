;;; (engine expr) -- compiling an expression AST into a procedure of a row.
;;;
;;; Compiling resolves every name and function and checks argument counts, so
;;; all name errors happen before any row is read (spec 1.7).  A compiled
;;; expression is a `cexpr`: proc maps a row (vector of values) to a value;
;;; affinity is integer, real, text or #f (spec 1.9).
(library (engine expr)
  (export make-level make-scope make-cexpr cexpr-proc cexpr-affinity cexpr-collation
          cexpr-collation-name cexpr-with-collation compile-expr
          level-correlated? make-correlation column-cexpr scope-has-column? binary-cexpr install-subquery-planner!
          make-aggregate-collector collector-specs collector-take-used!
          aggregate-spec-aggregate aggregate-spec-star aggregate-spec-distinct
          aggregate-spec-args aggregate-spec-order aggregate-spec-collation
          aggregate-spec-order-collations
          misuse-in-where misuse-in-order-by misuse-in-group-by)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine catalog) (engine sources)
          (engine plan) (engine operators) (engine functions) (engine aggregates) (engine windows))

  ;; collation (spec 7.3): #f for none, else (explicit . c) or (implicit . c), c being binary,
  ;; nocase or rtrim.  make-cexpr may leave it out.
  (define-record-type cexpr
    (fields proc affinity collation)
    (protocol (lambda (new)
                (case-lambda
                  [(proc affinity) (new proc affinity #f)]
                  [(proc affinity collation) (new proc affinity collation)]))))

  ;; The collation c's values compare under on their own (7.4): its collation, else binary.
  (define (cexpr-collation-name c)
    (let ([k (cexpr-collation c)]) (if k (cdr k) 'binary)))

  ;; The same expression with the explicit collation `coll` (a symbol).
  (define (cexpr-with-collation c coll)
    (make-cexpr (cexpr-proc c) (cexpr-affinity c) (cons 'explicit coll)))

  ;; The collation two compared expressions use (7.4); a, b: the `collation` of each, a being the left.
  (define (choose-collation a b)
    (cond [(and a (eq? (car a) 'explicit)) (cdr a)]
          [(and b (eq? (car b) 'explicit)) (cdr b)]
          [a (cdr a)]
          [b (cdr b)]
          [else 'binary]))

  ;; Aggregate calls (spec 3.2).  An aggregate query compiles its expressions against a
  ;; `collector`, which numbers each distinct call; a call's value is then read from slot
  ;; ncols+number of the row the executor builds (see (engine aggregation)).  Elsewhere the
  ;; scope holds a procedure (written-name -> message) saying why aggregates are not allowed.
  (define-record-type aggregate-spec
    (fields aggregate name key star distinct args order collation order-collations))
  ;; args: argument procs; order: list of (order-term . proc), for group_concat(... ORDER BY ...);
  ;; collation: that of the first argument (DISTINCT, min, max compare under it), order-collations:
  ;; that of each order term.
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

;; A level is one query's name environment: its sources, the scope of the query enclosing it
  ;; (or #f), and the row currently being evaluated, which subqueries below it read through
  ;; `box`.  `correlation` is a box shared by all levels of one query: set once any name
  ;; resolves outside it (the query then has to be re-run per row).
  (define-record-type (level make-level* level?) (fields db sources outer box correlation))
  (define make-level
    (case-lambda
      [(db sources outer) (make-level db sources outer (make-box #f))]
      [(db sources outer correlation) (make-level* db sources outer (make-box #f) correlation)]))
  (define (level-correlated? level) (unbox (level-correlation level)))
  (define (make-correlation) (make-box #f))
  (define (make-box v) (vector v))
  (define (unbox b) (vector-ref b 0))
  (define (set-box! b v) (vector-set! b 0 v))

  ;; level: the sources names refer to.  aliases: alist lower-cased alias -> (index . cexpr),
  ;; tried after the columns; the cdr may instead be a message string, which is the error a use
  ;; of that alias raises.  aggregates: an aggregate-collector, or a procedure as described above.
  ;; windows: a window-collector (window calls allowed, spec stage 6), or #f.
  (define-record-type (scope make-scope* scope?) (fields level aliases aggregates windows))
  (define make-scope
    (case-lambda
      [(level aliases) (make-scope* level aliases misuse-in-where #f)]
      [(level aliases aggregates) (make-scope* level aliases aggregates #f)]
      [(level aliases aggregates windows) (make-scope* level aliases aggregates windows)]))
  (define (scope-sources scope) (level-sources (scope-level scope)))

  (define (scope-has-column? scope lname)
    (pair? (sources-column-matches (scope-sources scope) lname)))

  (define (constant v) (make-cexpr (lambda (row) v) #f))

  ;; A column reference has its column's collation as an implicit one (7.3).
  (define column-cexpr
    (case-lambda
      [(index affinity) (column-cexpr index affinity 'binary)]
      [(index affinity collation)
       (make-cexpr (lambda (row) (vector-ref row index)) affinity (cons 'implicit collation))]))

  ;; `proc` (of a row of `scope`'s level), seen from `depth` levels further in.
  (define (seen-from-inside scope depth proc affinity collation)
    (if (zero? depth)
        (make-cexpr proc affinity collation)
        (let ([box (level-box (scope-level scope))])
          (make-cexpr (lambda (row) (proc (unbox box))) affinity collation))))

  ;; Names (spec 4.2): the innermost level that has the column wins.  Walking outwards marks
  ;; each level left as correlated.
  (define (resolve-column scope qualifier name)
    (let ([lname (ascii-downcase name)]
          [written (if qualifier (string-append qualifier "." name) name)])
      (define (no-such-column) (raise-sql-error (string-append "no such column: " written)))
      (define (column-at scope depth index)
        (let ([column (sources-ref (scope-sources scope) index)])
          (seen-from-inside scope depth (lambda (row) (vector-ref row index))
                            (column-type column) (cons 'implicit (column-collation column)))))
      (let walk ([scope scope] [depth 0])
        (let* ([level (scope-level scope)]
               [sources (level-sources level)]
               [go-outside (lambda ()
                             (let ([outer (level-outer level)])
                               (unless outer (no-such-column))
                               (set-box! (level-correlation level) #t)
                               (walk outer (+ depth 1))))])
          (if qualifier
              (let ([source (sources-named sources (ascii-downcase qualifier))])
                (cond [source (let ([i (source-column-index source lname)])
                                (if i (column-at scope depth (+ (source-offset source) i)) (no-such-column)))]
                      [else (go-outside)]))
              (let ([matches (sources-column-matches sources lname)]
                    [alias (assoc lname (scope-aliases scope))])
                (cond [(pair? matches)
                       (when (pair? (cdr matches)) (raise-sql-error (string-append "ambiguous column name: " name)))
                       (column-at scope depth (car matches))]
                      [(and alias (string? (cddr alias))) (raise-sql-error (cddr alias))]
                      [alias (seen-from-inside scope depth (cexpr-proc (cddr alias)) (cexpr-affinity (cddr alias))
                                               (cexpr-collation (cddr alias)))]
                      [else (go-outside)])))))))

  ;; A column of a `*` expansion, by absolute index in the innermost level.
  (define (resolve-slot scope index)
    (let ([column (sources-ref (scope-sources scope) index)])
      (column-cexpr index (column-type column) (column-collation column))))

  (define (wrong-argument-count name)
    (raise-sql-error (string-append "wrong number of arguments to function " name "()")))

  (define (misuse-of-window name) (string-append "misuse of window function " name "()"))

  (define (compile-call scope name args distinct? order star?)
    (let ([lname (ascii-downcase name)])
      (when (window-function-name? lname) (raise-sql-error (misuse-of-window name)))
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
      (let* ([inner (make-scope (scope-level scope) '() misuse-in-where)]
             [arg-cexprs (map (lambda (a) (compile-expr a inner)) args)]
             [arg-procs (map cexpr-proc arg-cexprs)]
             [order-cexprs (map (lambda (t) (compile-expr (order-term-expr t) inner)) order)]
             [order-procs (map (lambda (t c) (cons t (cexpr-proc c))) order order-cexprs)]
             [key (list lname distinct? star? args
                        (map (lambda (t) (list (order-term-expr t) (order-term-direction t) (order-term-nulls t)))
                             order))]
             [slot (+ (aggregate-collector-ncols collector)
                      (collector-register! collector
                                           (make-aggregate-spec agg name key star? distinct? arg-procs order-procs
                                                                 (if (pair? arg-cexprs) (cexpr-collation-name (car arg-cexprs)) 'binary)
                                                                 (map cexpr-collation-name order-cexprs))))])
        (aggregate-collector-used-set! collector (cons name (aggregate-collector-used collector)))
        (make-cexpr (lambda (row) (vector-ref row slot)) #f))))

  ;; f(...) OVER ...: the call is registered with the scope's window-collector, and reads its
  ;; value from the slot the executor appends to each row (see (engine windows)).  Its
  ;; expressions see the columns (and the aggregates of the query), not aliases or windows.
  (define (compile-window-call scope name args star? over)
    (let ([collector (scope-windows scope)] [lname (ascii-downcase name)] [n (length args)])
      (unless collector (raise-sql-error (misuse-of-window name)))
      (let* ([window-only? (window-function-name? lname)]
             [agg (and (not window-only?) (find-aggregate lname))])
        (unless (or window-only? agg) (raise-sql-error (string-append "no such function: " name)))
        (when (cond [window-only? (let ([arity (window-function-arity lname)])
                                    (or (< n (car arity)) (> n (cdr arity))))]
                    [star? (not (string=? lname "count"))]
                    [else (or (< n (aggregate-min-args agg)) (> n (aggregate-max-args agg)))])
          (wrong-argument-count name))
        (let* ([inner (make-scope (scope-level scope) '() (scope-aggregates scope))]
               [spec (resolve-window-spec (window-collector-definitions collector) over)]
               [terms (cadr spec)]
               [arg-cexprs (map (lambda (e) (compile-expr e inner)) args)]
               [partition-cexprs (map (lambda (e) (compile-expr e inner)) (car spec))]
               [order-cexprs (map (lambda (e) (compile-expr (order-term-expr e) inner)) terms)]
               [call (make-window-call (if window-only? (string->symbol lname) agg) star?
                                       (map cexpr-proc arg-cexprs) (map cexpr-proc partition-cexprs)
                                       terms (map cexpr-proc order-cexprs)
                                       (normalize-frame (caddr spec) (length terms))
                                       (if (pair? arg-cexprs) (cexpr-collation-name (car arg-cexprs)) 'binary)
                                       (map cexpr-collation-name partition-cexprs)
                                       (map cexpr-collation-name order-cexprs))]
               [k (window-collector-register! collector call)])
          (window-collector-note-used! collector name)
          (make-cexpr (lambda (row)
                        (vector-ref row (+ (- (vector-length row) (length (window-collector-calls collector))) k)))
                      #f)))))

  (define (lift2 f l r)
    (let ([lp (cexpr-proc l)] [rp (cexpr-proc r)])
      (make-cexpr (lambda (row) (f (lp row) (rp row))) #f)))

  ;; A comparison-like operator: `finish` takes the collation (7.4) and the converted operand values.
  (define (compile-comparison finish l r)
    (let-values ([(lconv rconv) (comparison-converters (cexpr-affinity l) (cexpr-affinity r))])
      (let ([lp (cexpr-proc l)] [rp (cexpr-proc r)]
            [coll (choose-collation (cexpr-collation l) (cexpr-collation r))])
        (make-cexpr (lambda (row)
                      (let ([a (lp row)] [b (rp row)])
                        (finish coll (if lconv (lconv a) a) (if rconv (rconv b) b))))
                    #f))))

  ;; A binary operator applied to two compiled operands.
  (define (binary-cexpr op l r)
    (case op
      [(+) (lift2 op-add l r)] [(-) (lift2 op-sub l r)] [(*) (lift2 op-mul l r)]
      [(/) (lift2 op-div l r)] [(%) (lift2 op-mod l r)]
      [(concat) (lift2 op-concat l r)]
      [(and) (lift2 op-and l r)] [(or) (lift2 op-or l r)]
      [(=) (compile-comparison (lambda (k a b) (op-compare zero? k a b)) l r)]
      [(!=) (compile-comparison (lambda (k a b) (op-compare (lambda (c) (not (zero? c))) k a b)) l r)]
      [(<) (compile-comparison (lambda (k a b) (op-compare negative? k a b)) l r)]
      [(<=) (compile-comparison (lambda (k a b) (op-compare (lambda (c) (<= c 0)) k a b)) l r)]
      [(>) (compile-comparison (lambda (k a b) (op-compare positive? k a b)) l r)]
      [(>=) (compile-comparison (lambda (k a b) (op-compare (lambda (c) (>= c 0)) k a b)) l r)]
      [(is) (compile-comparison op-is l r)]
      [(is-not) (compile-comparison (lambda (k a b) (op-not (op-is k a b))) l r)]
      [else (error 'compile-expr "unknown operator" op)]))

  (define (compile-binary scope op left right)
    (if (memq op '(= != < <= > >= is is-not))
        ;; `x IS NULL` with the literal does not count as a comparison (spec 4.3)
        (let ([null-test? (and (memq op '(is is-not)) (equal? right (list 'lit sql-null)))])
          (binary-cexpr op
                        (compile-operand scope left (not null-test?))
                        (compile-operand scope right #t)))
        (binary-cexpr op (compile-expr left scope) (compile-expr right scope))))

  ;;; ---- subqueries (spec 4.3) ----------------------------------------------------

  (define subquery-planner #f)
  ;; (engine select) installs its planner: (db select-stmt outer-scope) -> plan.
  (define (install-subquery-planner! f) (set! subquery-planner f))

  (define (plan-subquery scope stmt) (subquery-planner (level-db (scope-level scope)) stmt scope))

  ;; A procedure of the enclosing row giving the subquery's rows.  An uncorrelated subquery
  ;; runs once.
  (define (subquery-rows scope plan)
    (let ([box (level-box (scope-level scope))] [done? #f] [rows '()])
      (lambda (row)
        (unless (and done? (not (plan-correlated? plan)))
          (set-box! box row)
          (set! rows ((plan-run plan)))
          (set! done? #t))
        rows)))

  (define (single-column-plan scope stmt row-operand?)
    (let ([plan (plan-subquery scope stmt)])
      (unless (= 1 (length (plan-names plan)))
        (raise-sql-error (if row-operand?
                             "row value misused"
                             (string-append "sub-select returns " (number->string (length (plan-names plan)))
                                            " columns - expected 1"))))
      plan))

  ;; row-operand?: the subquery is a direct operand of a comparison, BETWEEN or CASE x.
  (define (compile-scalar-subquery scope stmt row-operand?)
    (let* ([plan (single-column-plan scope stmt row-operand?)]
           [rows-of (subquery-rows scope plan)])
      (make-cexpr (lambda (row)
                    (let ([rows (rows-of row)]) (if (null? rows) sql-null (vector-ref (car rows) 0))))
                  (car (plan-affinities plan)))))

  (define (compile-operand scope ast row-operand?)
    (if (eq? (car ast) 'subquery)
        (compile-scalar-subquery scope (cadr ast) row-operand?)
        (compile-expr ast scope)))

  ;; x IN (select): as the list form, but x and each value compare as `x = v` would (1.9).
  (define (compile-in-select scope negated? x stmt)
    (let* ([x (compile-expr x scope)]
           [plan (single-column-plan scope stmt #f)]
           [rows-of (subquery-rows scope plan)]
           [xp (cexpr-proc x)]
           [coll (choose-collation (cexpr-collation x) (car (plan-collations plan)))])
      (let-values ([(xconv vconv) (comparison-converters (cexpr-affinity x) (car (plan-affinities plan)))])
        (negate-if negated?
                   (make-cexpr (lambda (row)
                                 (let ([x (xp row)] [rows (rows-of row)])
                                   (op-in coll
                                          (if xconv (xconv x) x)
                                          (map (lambda (r) (if vconv (vconv (vector-ref r 0)) (vector-ref r 0)))
                                               rows))))
                               #f)))))

  (define (compile-exists scope stmt)
    (let ([rows-of (subquery-rows scope (plan-subquery scope stmt))])
      (make-cexpr (lambda (row) (if (null? (rows-of row)) 0 1)) #f)))

  (define (negate-if negated? c)
    (if negated? (lift1 op-not c) c))

  (define (lift1 f c)
    (let ([p (cexpr-proc c)]) (make-cexpr (lambda (row) (f (p row))) #f)))

  ;; x BETWEEN low AND high  ==  x >= low AND x <= high
  (define (compile-between scope negated? x low high)
    (let ([x (compile-operand scope x #t)])
      (negate-if negated?
                 (binary-cexpr 'and
                               (binary-cexpr '>= x (compile-operand scope low #t))
                               (binary-cexpr '<= x (compile-operand scope high #t))))))

  ;; Only x's affinity and collation count: every item is converted to the affinity.
  (define (compile-in scope negated? x items)
    (let* ([x (compile-expr x scope)]
           [xp (cexpr-proc x)]
           [convert (or (affinity-converter (cexpr-affinity x)) (lambda (v) v))]
           [coll (cexpr-collation-name x)]
           [procs (map (lambda (e) (cexpr-proc (compile-expr e scope))) items)])
      (negate-if negated?
                 (make-cexpr (lambda (row)
                               (op-in coll (xp row) (map (lambda (p) (convert (p row))) procs)))
                             #f))))

  (define (compile-like scope negated? x pattern)
    (negate-if negated? (lift2 op-like (compile-expr x scope) (compile-expr pattern scope))))

  (define (compile-cast scope x type)
    (let* ([c (compile-expr x scope)] [p (cexpr-proc c)])
      (make-cexpr (lambda (row) (cast-value type (p row))) type (cexpr-collation c))))

  ;; +e: e's value and collation, no affinity.
  (define (compile-pos scope x)
    (let ([c (compile-expr x scope)])
      (make-cexpr (cexpr-proc c) #f (cexpr-collation c))))

  ;; x COLLATE name: x's value and affinity, the explicit collation (7.2, 7.3).
  (define (compile-collate scope x name)
    (let ([coll (collation-named name)])
      (cexpr-with-collation (compile-expr x scope) coll)))

  ;; whens: list of (condition . result); operand is #f for the searched form.
  (define (compile-case scope operand whens else-expr)
    (let* ([operand (and operand (compile-operand scope operand #t))]
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
      [(pos) (compile-pos scope (cadr ast))]
      [(collate) (compile-collate scope (cadr ast) (caddr ast))]
      [(not) (compile-unary op-not (cadr ast) scope)]
      [(bin) (compile-binary scope (cadr ast) (caddr ast) (cadddr ast))]
      [(call) (apply compile-call scope (cdr ast))]
      [(window-call) (apply compile-window-call scope (cdr ast))]
      [(case) (compile-case scope (cadr ast) (caddr ast) (cadddr ast))]
      [(between) (apply compile-between scope (cdr ast))]
      [(in) (apply compile-in scope (cdr ast))]
      [(like) (apply compile-like scope (cdr ast))]
      [(cast) (compile-cast scope (cadr ast) (caddr ast))]
      [(subquery) (compile-scalar-subquery scope (cadr ast) #f)]
      [(in-select) (apply compile-in-select scope (cdr ast))]
      [(exists) (compile-exists scope (cadr ast))]
      [(slot) (resolve-slot scope (cadr ast))]
      [else (error 'compile-expr "unknown expression" ast)])))
