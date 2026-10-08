;;; (engine expr) -- compiling an expression AST into a procedure of a row.
;;;
;;; Compiling resolves every name and function and checks argument counts, so
;;; all name errors happen before any row is read (spec 1.7).  A compiled
;;; expression is a `cexpr`: proc maps a row (vector of values) to a value;
;;; affinity is integer, real, text or #f (spec 1.9).
(library (engine expr)
  (export make-scope make-cexpr cexpr-proc cexpr-affinity compile-expr)
  (import (rnrs) (engine errors) (engine values) (engine ast)
          (engine catalog) (engine operators) (engine functions))

  (define-record-type cexpr (fields proc affinity))

  ;; table: the table whose columns names refer to, or #f (no row in scope).
  ;; aliases: alist lower-cased alias -> (index . cexpr), tried after the columns.
  (define-record-type scope (fields table aliases))

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
            [alias (cddr alias)]
            [else (raise-sql-error (string-append "no such column: " written))])))

  (define (compile-call scope name args)
    (let ([fn (find-function (ascii-downcase name))])
      (unless fn (raise-sql-error (string-append "no such function: " name)))
      (let ([n (length args)])
        (when (or (< n (function-min-args fn))
                  (and (function-max-args fn) (> n (function-max-args fn))))
          (raise-sql-error (string-append "wrong number of arguments to function " name "()"))))
      (let ([procs (map (lambda (a) (cexpr-proc (compile-expr a scope))) args)]
            [f (function-proc fn)])
        (make-cexpr (lambda (row) (f (map (lambda (p) (p row)) procs))) #f))))

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

  (define (compile-binary scope op left right)
    (let ([l (compile-expr left scope)] [r (compile-expr right scope)])
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
        [else (error 'compile-expr "unknown operator" op)])))

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
      [(call) (compile-call scope (cadr ast) (caddr ast))]
      [else (error 'compile-expr "unknown expression" ast)])))
