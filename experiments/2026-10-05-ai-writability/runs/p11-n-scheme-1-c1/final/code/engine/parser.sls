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
            [(kw? t 'select) (parse-query p)]
            [(kw? t 'with) (parse-query p)]
            [(kw? t 'alter) (advance! p) (parse-alter p)]
            [(kw? t 'begin) (advance! p) (parse-transaction p 'begin)]
            [(or (kw? t 'commit) (kw? t 'end)) (advance! p) (parse-transaction p 'commit)]
            [(kw? t 'rollback) (advance! p) (parse-transaction p 'rollback)]
            [(kw? t 'update) (advance! p) (parse-update p)]
            [(kw? t 'delete) (advance! p) (parse-delete p)]
            [else (raise-syntax-error)])))

  (define (parse-transaction p kind)
    (accept-kw! p 'transaction)
    (make-transaction kind))

  ;; After CREATE.
  (define (parse-create p)
    (cond [(accept-kw! p 'table) (parse-create-table p)]
          [(accept-kw! p 'view) (parse-create-view p)]
          [(accept-kw! p 'unique) (expect-kw! p 'index) (parse-create-index p #t)]
          [(accept-kw! p 'index) (parse-create-index p #f)]
          [else (raise-syntax-error)]))

  (define (parse-if-not-exists p)
    (and (accept-kw! p 'if) (begin (expect-kw! p 'not) (expect-kw! p 'exists) #t)))

  (define (parse-if-exists p)
    (and (accept-kw! p 'if) (begin (expect-kw! p 'exists) #t)))

  ;; name [( column, ... )] AS query
  (define (parse-create-view p)
    (let* ([if-not-exists (parse-if-not-exists p)]
           [name (expect-name! p)]
           [columns (and (op? (peek p) "(") (parse-name-list p))])
      (expect-kw! p 'as)
      (make-create-view name if-not-exists columns (parse-query p))))

  ;; name ON table ( column [COLLATE name] [ASC|DESC], ... )
  (define (parse-create-index p unique?)
    (let* ([if-not-exists (parse-if-not-exists p)]
           [name (expect-name! p)]
           [table (begin (expect-kw! p 'on) (expect-name! p))]
           [entries (begin (expect-op! p "(")
                           (parse-comma-list p (lambda (p)
                                                 (let* ([c (expect-name! p)]
                                                        [coll (and (accept-kw! p 'collate) (expect-name! p))])
                                                   (or (accept-kw! p 'asc) (accept-kw! p 'desc))
                                                   (cons c coll)))))])
      (expect-op! p ")")
      (make-create-index name unique? if-not-exists table (map car entries) (map cdr entries))))

  ;; After ALTER.
  (define (parse-alter p)
    (expect-kw! p 'table)
    (let ([table (expect-name! p)])
      (cond
        [(accept-kw! p 'add)
         (accept-kw! p 'column)
         (make-alter-add-column table (parse-column-def p))]
        [(accept-kw! p 'rename)
         (cond [(accept-kw! p 'to) (make-alter-rename-table table (expect-name! p))]
               [else
                (accept-kw! p 'column)
                (let* ([old (expect-name! p)]
                       [new (begin (expect-kw! p 'to) (expect-name! p))])
                  (make-alter-rename-column table old new))])]
        [else (raise-syntax-error)])))

  (define (parse-create-table p)
    (let* ([if-not-exists (parse-if-not-exists p)]
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
      (let loop ([not-null #f] [pk #f] [uq #f] [default #f] [collation #f])
        (cond
          [(accept-kw! p 'primary) (expect-kw! p 'key) (loop not-null #t uq default collation)]
          [(accept-kw! p 'not) (expect-kw! p 'null) (loop #t pk uq default collation)]
          [(accept-kw! p 'unique) (loop not-null pk #t default collation)]
          [(accept-kw! p 'default) (loop not-null pk uq (list (parse-default-value p)) collation)]
          [(accept-kw! p 'collate) (loop not-null pk uq default (expect-name! p))]
          [else (make-column-def name sym not-null pk uq default collation)]))))

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
    (let* ([kind (cond [(accept-kw! p 'table) make-drop-table]
                       [(accept-kw! p 'view) make-drop-view]
                       [(accept-kw! p 'index) make-drop-index]
                       [else (raise-syntax-error)])]
           [if-exists (parse-if-exists p)]
           [name (expect-name! p)])
      (kind name if-exists)))

  (define (parse-insert p)
    (expect-kw! p 'into)
    (let* ([table (expect-name! p)]
           [columns (and (accept-op! p "(")
                         (let ([names (parse-comma-list p expect-name!)])
                           (expect-op! p ")")
                           names))])
      (cond [(accept-kw! p 'values)
             (make-insert table columns (parse-comma-list p parse-value-row))]
            [(or (kw? (peek p) 'select) (kw? (peek p) 'with))
             (make-insert table columns (parse-query p))]
            [else (raise-syntax-error)])))

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

  ;; A query (5.1, 5.2) at its SELECT or WITH.
  (define (parse-query p)
    (if (accept-kw! p 'with) (parse-with p) (parse-compound p)))

  ;; After WITH: ctes, then the select (or, at the top of a statement, an INSERT).
  (define (parse-with p)
    (let* ([recursive? (accept-kw! p 'recursive)]
           [ctes (parse-comma-list p parse-cte)])
      (make-with-stmt recursive? ctes
                      (if (accept-kw! p 'insert) (parse-insert p) (parse-compound p)))))

  (define (parse-cte p)
    (let* ([name (expect-name! p)]
           [columns (and (op? (peek p) "(") (parse-name-list p))])
      (expect-kw! p 'as)
      (make-cte name columns (parse-paren-select p))))

  ;; simple-select [compound-op simple-select]... [ORDER BY ...] [LIMIT ... [OFFSET ...]]
  (define (parse-compound p)
    (let* ([first (begin (expect-kw! p 'select) (parse-select p))]
           [rest (let loop ([acc '()])
                   (let ([op (cond [(accept-kw! p 'union) (if (accept-kw! p 'all) 'union-all 'union)]
                                   [(accept-kw! p 'intersect) 'intersect]
                                   [(accept-kw! p 'except) 'except]
                                   [else #f])])
                     (if op
                         (let ([s (begin (expect-kw! p 'select) (parse-select p))])
                           (loop (cons (cons op s) acc)))
                         (reverse acc))))]
           [order (if (accept-kw! p 'order)
                      (begin (expect-kw! p 'by) (parse-comma-list p parse-order-term))
                      '())]
           [limit (and (accept-kw! p 'limit) (parse-expr p))]
           [offset (and limit (accept-kw! p 'offset) (parse-expr p))])
      (if (null? rest)
          (make-select-stmt (select-stmt-distinct? first) (select-stmt-items first) (select-stmt-from first)
                            (select-stmt-where first) (select-stmt-group first) (select-stmt-having first)
                            order limit offset (select-stmt-windows first))
          (make-compound first rest order limit offset))))

  ;; One simple-select, after SELECT; it has no ORDER BY or LIMIT of its own.
  (define (parse-select p)
    (let* ([distinct? (cond [(accept-kw! p 'distinct) #t] [(accept-kw! p 'all) #f] [else #f])]
           [items (parse-comma-list p parse-result-column)]
           [from (and (accept-kw! p 'from) (parse-from p))]
           [where (and (accept-kw! p 'where) (parse-expr p))]
           [group (if (accept-kw! p 'group)
                      (begin (expect-kw! p 'by) (parse-comma-list p parse-expr))
                      '())]
           [having (and (accept-kw! p 'having) (parse-expr p))]
           [windows (if (accept-kw! p 'window) (parse-comma-list p parse-window-definition) '())])
      (make-select-stmt distinct? items from where group having '() #f #f windows)))

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

  (define (query-start? t) (or (kw? t 'select) (kw? t 'with)))

  ;; ( query )
  (define (parse-paren-select p)
    (expect-op! p "(")
    (unless (query-start? (peek p)) (raise-syntax-error))
    (let ([stmt (parse-query p)])
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
      [(and (kw? (peek p) 'in) (op? (peek-at p 1) "(") (query-start? (peek-at p 2)))
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
        [else (parse-postfix p)])))

  ;; primary [COLLATE name]...: the postfix COLLATE binds tighter than any operator (7.2).
  (define (parse-postfix p)
    (let loop ([e (parse-primary p)])
      (if (accept-kw! p 'collate)
          (loop (list 'collate e (expect-name! p)))
          e)))

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
         (cond [(and (op? t "(") (query-start? (peek-at p 1))) (list 'subquery (parse-paren-select p))]
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
        [(accept-op! p ")") (list 'call name '() #f '() #f (parse-over p))]
        [(accept-op! p "*") (expect-op! p ")") (list 'call name '() #f '() #t (parse-over p))]
        [else
         (let* ([distinct? (accept-kw! p 'distinct)]
                [args (parse-comma-list p parse-expr)]
                [order (if (accept-kw! p 'order)
                           (begin (expect-kw! p 'by) (parse-comma-list p parse-order-term))
                           '())])
           (expect-op! p ")")
           (list 'call name args distinct? order #f (parse-over p)))])))

  ;; ---- window functions (6.1) ----

  ;; [OVER window-name | OVER ( window-spec )], or #f
  (define (parse-over p)
    (and (accept-kw! p 'over)
         (if (ident? (peek p)) (expect-name! p) (parse-window-spec p))))

  ;; name AS ( window-spec )
  (define (parse-window-definition p)
    (let ([name (expect-name! p)])
      (expect-kw! p 'as)
      (cons name (parse-window-spec p))))

  ;; ( [base] [PARTITION BY expr, ...] [ORDER BY term, ...] [frame] )
  (define (parse-window-spec p)
    (expect-op! p "(")
    (let* ([base (and (ident? (peek p)) (expect-name! p))]
           [partition (if (accept-kw! p 'partition)
                          (begin (expect-kw! p 'by) (parse-comma-list p parse-expr))
                          '())]
           [order (if (accept-kw! p 'order)
                      (begin (expect-kw! p 'by) (parse-comma-list p parse-order-term))
                      '())]
           [frame (cond [(accept-kw! p 'rows) (parse-frame p 'rows)]
                        [(accept-kw! p 'range) (parse-frame p 'range)]
                        [else #f])])
      (expect-op! p ")")
      (list 'wspec base partition order frame)))

  ;; After ROWS / RANGE: a start alone means BETWEEN start AND CURRENT ROW.
  (define (parse-frame p units)
    (if (accept-kw! p 'between)
        (let* ([start (parse-frame-bound p)]
               [end (begin (expect-kw! p 'and) (parse-frame-bound p))])
          (list units start end))
        (list units (parse-frame-bound p) (list 'current-row))))

  (define (parse-frame-bound p)
    (cond
      [(accept-kw! p 'unbounded)
       (cond [(accept-kw! p 'preceding) (list 'unbounded-preceding)]
             [(accept-kw! p 'following) (list 'unbounded-following)]
             [else (raise-syntax-error)])]
      [(accept-kw! p 'current) (expect-kw! p 'row) (list 'current-row)]
      [else
       (let* ([negative? (accept-op! p "-")]
              [t (peek p)])
         (unless (and t (memq (token-kind t) '(int real))) (raise-syntax-error))
         (advance! p)
         (let ([n (if (eq? (token-kind t) 'int) (normalize-number (token-value t)) (token-value t))])
           (cond [(accept-kw! p 'preceding) (list 'preceding (if negative? (- n) n))]
                 [(accept-kw! p 'following) (list 'following (if negative? (- n) n))]
                 [else (raise-syntax-error)])))])))
