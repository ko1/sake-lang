;;; Parsing (1.4 - 1.8, 2.1 - 2.3, 4.1 - 4.3): a statement's tokens into the syntax tree of (engine ast).
(library (engine parser)
  (export parse-statement)
  (import (rnrs) (engine errors) (engine lexer) (engine ast) (engine numeric))

  (define-record-type pstate (fields tokens (mutable pos)))

  (define (peek p)
    (let ([toks (pstate-tokens p)] [i (pstate-pos p)])
      (and (< i (vector-length toks)) (vector-ref toks i))))
  (define (peek-at p k)
    (let ([toks (pstate-tokens p)] [i (+ (pstate-pos p) k)])
      (and (< i (vector-length toks)) (vector-ref toks i))))
  (define (advance! p) (pstate-pos-set! p (+ (pstate-pos p) 1)))

  (define (kw? t sym) (and t (eq? (token-kind t) 'kw) (eq? (token-value t) sym)))
  (define (op? t str) (and t (eq? (token-kind t) 'op) (string=? (token-value t) str)))

  (define (accept-kw! p sym) (and (kw? (peek p) sym) (begin (advance! p) #t)))
  (define (accept-op! p str) (and (op? (peek p) str) (begin (advance! p) #t)))
  (define (expect-kw! p sym) (unless (accept-kw! p sym) (raise-syntax-error)))
  (define (expect-op! p str) (unless (accept-op! p str) (raise-syntax-error)))

  (define (expect-name! p)
    (let ([t (peek p)])
      (unless (and t (eq? (token-kind t) 'ident)) (raise-syntax-error))
      (advance! p)
      (make-name (token-text t) (token-value t))))

  ;; ---- statements ----

  (define (parse-statement token-list)
    (let* ([p (make-pstate (list->vector token-list) 0)]
           [stmt (parse-statement-body p)])
      (when (peek p) (raise-syntax-error))
      stmt))

  (define (parse-statement-body p)
    (let ([t (peek p)])
      (cond [(kw? t 'create) (advance! p) (parse-create p)]
            [(kw? t 'drop) (advance! p) (parse-drop p)]
            [(kw? t 'insert) (advance! p) (parse-insert p)]
            [(kw? t 'select) (advance! p) (parse-select p)]
            [(kw? t 'update) (advance! p) (parse-update p)]
            [(kw? t 'delete) (advance! p) (parse-delete p)]
            [else (raise-syntax-error)])))

  (define (parse-create p)
    (expect-kw! p 'table)
    (let* ([if-not-exists (and (accept-kw! p 'if)
                               (begin (expect-kw! p 'not) (expect-kw! p 'exists) #t))]
           [name (expect-name! p)])
      (expect-op! p "(")
      (let ([elements (parse-comma-list p parse-table-element)])
        (expect-op! p ")")
        (let-values ([(columns constraints) (partition column-def? elements)])
          ;; table constraints come after all column definitions
          (let loop ([es elements] [in-constraints #f])
            (unless (null? es)
              (cond [(table-constraint? (car es)) (loop (cdr es) #t)]
                    [in-constraints (raise-syntax-error)]
                    [else (loop (cdr es) #f)])))
          (when (null? columns) (raise-syntax-error))
          (make-create-table name if-not-exists columns constraints)))))

  (define (parse-table-element p)
    (let ([t (peek p)])
      (cond [(kw? t 'primary)
             (advance! p) (expect-kw! p 'key)
             (make-table-constraint 'primary-key (parse-name-list p))]
            [(kw? t 'unique)
             (advance! p)
             (make-table-constraint 'unique (parse-name-list p))]
            [else (parse-column-def p)])))

  (define (parse-name-list p)
    (expect-op! p "(")
    (let ([names (parse-comma-list p expect-name!)])
      (expect-op! p ")")
      names))

  (define (parse-column-def p)
    (let* ([name (expect-name! p)]
           [type (expect-name! p)]
           [sym (cond [(string=? (name-lower type) "integer") 'integer]
                      [(string=? (name-lower type) "real") 'real]
                      [(string=? (name-lower type) "text") 'text]
                      [else (raise-syntax-error)])])
      (let loop ([not-null #f] [pk #f] [uq #f] [default #f])
        (cond
          [(accept-kw! p 'primary) (expect-kw! p 'key) (loop not-null #t uq default)]
          [(accept-kw! p 'not) (expect-kw! p 'null) (loop #t pk uq default)]
          [(accept-kw! p 'unique) (loop not-null pk #t default)]
          [(accept-kw! p 'default) (loop not-null pk uq (list (parse-default-value p)))]
          [else (make-column-def name sym not-null pk uq default)]))))

  ;; [+ | -] numeric-literal | string-literal | NULL
  (define (parse-default-value p)
    (let* ([sign (cond [(accept-op! p "-") -1] [(accept-op! p "+") 1] [else #f])]
           [t (peek p)])
      (unless t (raise-syntax-error))
      (cond
        [(memq (token-kind t) '(int real))
         (advance! p)
         (let ([v (token-value t)])
           (normalize-number (if (eqv? sign -1) (- v) v)))]
        [sign (raise-syntax-error)]
        [(eq? (token-kind t) 'str) (advance! p) (token-value t)]
        [(kw? t 'null) (advance! p) 'null]
        [else (raise-syntax-error)])))

  (define (parse-update p)
    (let* ([table (expect-name! p)]
           [assignments (begin (expect-kw! p 'set) (parse-comma-list p parse-assignment))]
           [where (and (accept-kw! p 'where) (parse-expr p))])
      (make-update table assignments where)))

  (define (parse-assignment p)
    (let ([nm (expect-name! p)])
      (expect-op! p "=")
      (cons nm (parse-expr p))))

  (define (parse-delete p)
    (expect-kw! p 'from)
    (let* ([table (expect-name! p)]
           [where (and (accept-kw! p 'where) (parse-expr p))])
      (make-delete table where)))

  (define (parse-drop p)
    (expect-kw! p 'table)
    (let* ([if-exists (and (accept-kw! p 'if) (begin (expect-kw! p 'exists) #t))]
           [name (expect-name! p)])
      (make-drop-table name if-exists)))

  (define (parse-insert p)
    (expect-kw! p 'into)
    (let* ([table (expect-name! p)]
           [columns (and (accept-op! p "(")
                         (let ([names (parse-comma-list p expect-name!)])
                           (expect-op! p ")")
                           names))])
      (expect-kw! p 'values)
      (let ([rows (parse-comma-list p parse-value-row)])
        (make-insert table columns rows))))

  (define (parse-value-row p)
    (expect-op! p "(")
    (let ([exprs (parse-comma-list p parse-expr)])
      (expect-op! p ")")
      exprs))

  (define (parse-comma-list p parse-item)
    (let loop ([acc (list (parse-item p))])
      (if (accept-op! p ",")
          (let ([item (parse-item p)]) (loop (cons item acc)))
          (reverse acc))))

  (define (parse-select p)
    (let* ([distinct? (cond [(accept-kw! p 'distinct) #t] [(accept-kw! p 'all) #f] [else #f])]
           [items (parse-comma-list p parse-result-column)]
           [from (and (accept-kw! p 'from) (parse-from p))]
           [where (and (accept-kw! p 'where) (parse-expr p))]
           [group (if (accept-kw! p 'group)
                      (begin (expect-kw! p 'by) (parse-comma-list p parse-expr))
                      '())]
           [having (and (accept-kw! p 'having) (parse-expr p))]
           [order (if (accept-kw! p 'order)
                      (begin (expect-kw! p 'by) (parse-comma-list p parse-order-term))
                      '())]
           [limit (and (accept-kw! p 'limit) (parse-expr p))]
           [offset (and limit (accept-kw! p 'offset) (parse-expr p))])
      (make-select-stmt distinct? items from where group having order limit offset)))

  (define (parse-result-column p)
    (cond
      [(accept-op! p "*") (make-result-column 'star #f)]
      [(and (ident? (peek p)) (op? (peek-at p 1) ".") (op? (peek-at p 2) "*"))
       (let ([q (expect-name! p)])
         (advance! p) (advance! p)
         (make-result-column (list 'qstar q) #f))]
      [else
       (let ([expr (parse-expr p)])
         (make-result-column expr (parse-optional-alias p)))]))

  (define (ident? t) (and t (eq? (token-kind t) 'ident)))

  ;; [AS] alias, or #f
  (define (parse-optional-alias p)
    (cond [(accept-kw! p 'as) (expect-name! p)]
          [(ident? (peek p)) (expect-name! p)]
          [else #f]))

  ;; ---- FROM (4.1) ----

  (define (parse-from p)
    (let loop ([left (parse-from-item p)])
      (cond
        [(accept-op! p ",") (loop (make-from-join 'cross left (parse-from-item p) #f))]
        [(accept-join-op! p)
         => (lambda (kind)
              (let* ([right (parse-from-item p)]
                     [constraint (parse-join-constraint p)])
                (when (and (eq? kind 'left) (not constraint)) (raise-syntax-error))
                (loop (make-from-join kind left right constraint))))]
        [else left])))

  ;; Consumes [INNER] JOIN, CROSS JOIN or LEFT [OUTER] JOIN; returns inner, cross, left, or #f.
  (define (accept-join-op! p)
    (cond [(accept-kw! p 'join) 'inner]
          [(and (kw? (peek p) 'inner) (kw? (peek-at p 1) 'join)) (advance! p) (advance! p) 'inner]
          [(and (kw? (peek p) 'cross) (kw? (peek-at p 1) 'join)) (advance! p) (advance! p) 'cross]
          [(accept-kw! p 'left) (accept-kw! p 'outer) (expect-kw! p 'join) 'left]
          [else #f]))

  (define (parse-join-constraint p)
    (cond [(accept-kw! p 'on) (cons 'on (parse-expr p))]
          [(accept-kw! p 'using) (cons 'using (parse-name-list p))]
          [else #f]))

  (define (parse-from-item p)
    (if (op? (peek p) "(")
        (let ([stmt (parse-paren-select p)])
          (make-from-subquery stmt (parse-optional-alias p)))
        (let ([nm (expect-name! p)])
          (make-from-table nm (parse-optional-alias p)))))

  ;; ( SELECT ... )
  (define (parse-paren-select p)
    (expect-op! p "(")
    (expect-kw! p 'select)
    (let ([stmt (parse-select p)])
      (expect-op! p ")")
      stmt))

  (define (parse-order-term p)
    (let* ([expr (parse-expr p)]
           [desc (cond [(accept-kw! p 'desc) #t] [(accept-kw! p 'asc) #f] [else #f])]
           [nulls (and (accept-kw! p 'nulls)
                       (cond [(accept-kw! p 'first) 'first]
                             [(accept-kw! p 'last) 'last]
                             [else (raise-syntax-error)]))])
      (make-order-term expr desc nulls)))

  ;; ---- expressions: one function per precedence level, loosest first (1.8) ----

  (define (parse-expr p) (parse-or p))

  (define (parse-or p)
    (let loop ([left (parse-and p)])
      (if (accept-kw! p 'or)
          (let ([right (parse-and p)]) (loop (list 'binop 'or left right)))
          left)))

  (define (parse-and p)
    (let loop ([left (parse-not p)])
      (if (accept-kw! p 'and)
          (let ([right (parse-not p)]) (loop (list 'binop 'and left right)))
          left)))

  (define (parse-not p)
    (if (accept-kw! p 'not)
        (list 'not (parse-not p))
        (parse-equality p)))

  (define (parse-equality p)
    (let loop ([left (parse-comparison p)])
      (let ([t (peek p)])
        (cond
          [(or (op? t "=") (op? t "=="))
           (advance! p) (let ([r (parse-comparison p)]) (loop (list 'binop 'eq left r)))]
          [(or (op? t "!=") (op? t "<>"))
           (advance! p) (let ([r (parse-comparison p)]) (loop (list 'binop 'ne left r)))]
          [(kw? t 'is)
           (advance! p)
           (let* ([negated (accept-kw! p 'not)]
                  [r (parse-comparison p)])
             (loop (list 'binop (if negated 'isnot 'is) left r)))]
          [(or (kw? t 'in) (kw? t 'like) (kw? t 'between))
           (loop (parse-membership p left #f))]
          [(and (kw? t 'not) (or (kw? (peek-at p 1) 'in) (kw? (peek-at p 1) 'like)
                                 (kw? (peek-at p 1) 'between)))
           (advance! p)
           (loop (parse-membership p left #t))]
          [else left]))))

  ;; IN, LIKE or BETWEEN (and their NOT forms) after the left operand (2.3).
  (define (parse-membership p left negated)
    (cond
      [(and (kw? (peek p) 'in) (op? (peek-at p 1) "(") (kw? (peek-at p 2) 'select))
       (advance! p)
       (list 'insub left (parse-paren-select p) negated)]
      [(accept-kw! p 'in)
       (expect-op! p "(")
       (let ([items (if (accept-op! p ")")
                        '()
                        (let ([l (parse-comma-list p parse-expr)]) (expect-op! p ")") l))])
         (list 'in left items negated))]
      [(accept-kw! p 'like) (list 'like left (parse-comparison p) negated)]
      [else
       (expect-kw! p 'between)
       (let* ([low (parse-comparison p)]
              [high (begin (expect-kw! p 'and) (parse-comparison p))])
         (list 'between left low high negated))]))

  (define (parse-comparison p)
    (let loop ([left (parse-additive p)])
      (let* ([t (peek p)]
             [op (cond [(op? t "<") 'lt] [(op? t "<=") 'le] [(op? t ">") 'gt] [(op? t ">=") 'ge]
                       [else #f])])
        (if op
            (begin (advance! p) (let ([r (parse-additive p)]) (loop (list 'binop op left r))))
            left))))

  (define (parse-additive p)
    (let loop ([left (parse-multiplicative p)])
      (let* ([t (peek p)]
             [op (cond [(op? t "+") 'plus] [(op? t "-") 'minus] [else #f])])
        (if op
            (begin (advance! p) (let ([r (parse-multiplicative p)]) (loop (list 'binop op left r))))
            left))))

  (define (parse-multiplicative p)
    (let loop ([left (parse-concat p)])
      (let* ([t (peek p)]
             [op (cond [(op? t "*") 'times] [(op? t "/") 'divide] [(op? t "%") 'modulo] [else #f])])
        (if op
            (begin (advance! p) (let ([r (parse-concat p)]) (loop (list 'binop op left r))))
            left))))

  (define (parse-concat p)
    (let loop ([left (parse-unary p)])
      (if (accept-op! p "||")
          (let ([r (parse-unary p)]) (loop (list 'binop 'concat left r)))
          left)))

  ;; An integer literal beyond 64 bits is a REAL, except that -9223372036854775808 is an INTEGER.
  (define (parse-unary p)
    (let ([t (peek p)])
      (cond
        [(op? t "-")
         (advance! p)
         (let ([next (peek p)])
           (if (and next (eq? (token-kind next) 'int) (= (token-value next) (- int64-min)))
               (begin (advance! p) (list 'lit int64-min))
               (list 'neg (parse-unary p))))]
        [(op? t "+") (advance! p) (list 'pos (parse-unary p))]
        [else (parse-primary p)])))

  (define (parse-primary p)
    (let ([t (peek p)])
      (unless t (raise-syntax-error))
      (case (token-kind t)
        [(int) (advance! p) (list 'lit (normalize-number (token-value t)))]
        [(real str) (advance! p) (list 'lit (token-value t))]
        [(kw)
         (cond [(kw? t 'null) (advance! p) (list 'lit 'null)]
               [(kw? t 'case) (advance! p) (parse-case p)]
               [(kw? t 'cast) (advance! p) (parse-cast p)]
               [(kw? t 'exists) (advance! p) (list 'exists (parse-paren-select p))]
               [else (raise-syntax-error)])]
        [(ident)
         (cond [(op? (peek-at p 1) "(") (parse-call p)]
               [(and (op? (peek-at p 1) ".") (ident? (peek-at p 2)))
                (let* ([q (expect-name! p)] [c (begin (advance! p) (expect-name! p))])
                  (list 'qcol q c))]
               [else (list 'col (expect-name! p))])]
        [(op)
         (cond [(and (op? t "(") (kw? (peek-at p 1) 'select)) (list 'subquery (parse-paren-select p))]
               [(op? t "(")
                (advance! p)
                (let ([e (parse-expr p)]) (expect-op! p ")") e)]
               [else (raise-syntax-error)])]
        [else (raise-syntax-error)])))

  (define (parse-case p)
    (let* ([operand (and (not (kw? (peek p) 'when)) (parse-expr p))]
           [whens (let loop ([acc '()])
                    (if (accept-kw! p 'when)
                        (let* ([c (parse-expr p)]
                               [r (begin (expect-kw! p 'then) (parse-expr p))])
                          (loop (cons (cons c r) acc)))
                        (reverse acc)))]
           [else-expr (and (accept-kw! p 'else) (parse-expr p))])
      (when (null? whens) (raise-syntax-error))
      (expect-kw! p 'end)
      (list 'case operand whens else-expr)))

  (define (parse-cast p)
    (expect-op! p "(")
    (let* ([e (parse-expr p)]
           [type (begin (expect-kw! p 'as) (expect-name! p))]
           [sym (cond [(string=? (name-lower type) "integer") 'integer]
                      [(string=? (name-lower type) "real") 'real]
                      [(string=? (name-lower type) "text") 'text]
                      [else (raise-syntax-error)])])
      (expect-op! p ")")
      (list 'cast e sym)))

  ;; name ( [*] | [DISTINCT] expr [, expr]... [ORDER BY term [, term]...] )
  (define (parse-call p)
    (let ([name (expect-name! p)])
      (expect-op! p "(")
      (cond
        [(accept-op! p ")") (list 'call name '() #f '() #f)]
        [(accept-op! p "*") (expect-op! p ")") (list 'call name '() #f '() #t)]
        [else
         (let* ([distinct? (accept-kw! p 'distinct)]
                [args (parse-comma-list p parse-expr)]
                [order (if (accept-kw! p 'order)
                           (begin (expect-kw! p 'by) (parse-comma-list p parse-order-term))
                           '())])
           (expect-op! p ")")
           (list 'call name args distinct? order #f))]))))
