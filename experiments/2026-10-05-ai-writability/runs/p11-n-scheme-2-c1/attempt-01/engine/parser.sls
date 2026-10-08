;;; (engine parser) -- tokens of one statement to a statement record (engine ast).
;;;
;;; Recursive descent; the expression levels follow the precedence table of 1.8,
;;; loosest first: OR, AND, NOT, equality/IS/IN/LIKE/BETWEEN, comparison, + -, * / %, ||, unary.
(library (engine parser)
  (export parse-statement)
  (import (rnrs) (engine errors) (engine values) (engine lexer) (engine ast))

  (define-record-type cursor (fields tokens (mutable pos)))

  (define (syntax-error) (raise-sql-error "syntax error"))

  (define (peek-at p k)
    (let ([i (+ (cursor-pos p) k)] [v (cursor-tokens p)])
      (and (< i (vector-length v)) (vector-ref v i))))
  (define (peek p) (peek-at p 0))
  (define (advance! p) (cursor-pos-set! p (+ 1 (cursor-pos p))))
  (define (retreat! p) (cursor-pos-set! p (- (cursor-pos p) 1)))
  (define (next! p) (let ([t (peek p)]) (unless t (syntax-error)) (advance! p) t))

  (define (token-is? t kind value) (and t (eq? (token-kind t) kind) (eq? (token-value t) value)))
  (define (at-keyword? p kw) (token-is? (peek p) 'keyword kw))
  (define (at-op? p op) (token-is? (peek p) 'op op))
  (define (accept-keyword! p kw) (and (at-keyword? p kw) (begin (advance! p) #t)))
  (define (accept-op! p op) (and (at-op? p op) (begin (advance! p) #t)))
  (define (expect-keyword! p kw) (unless (accept-keyword! p kw) (syntax-error)))
  (define (expect-op! p op) (unless (accept-op! p op) (syntax-error)))
  (define (at-ident? p) (let ([t (peek p)]) (and t (eq? (token-kind t) 'ident))))
  (define (expect-ident! p)
    (unless (at-ident? p) (syntax-error))
    (token-value (next! p)))

  ;;; ---- expressions ---------------------------------------------------------

  ;; Left-associative binary level: operand parser plus alist token-op -> ast-op.
  (define (parse-binary-level p operand ops)
    (let loop ([left (operand p)])
      (let* ([t (peek p)]
             [entry (and t (eq? (token-kind t) 'op) (assq (token-value t) ops))])
        (if entry
            (begin (advance! p) (loop (list 'bin (cdr entry) left (operand p))))
            left))))

  (define (parse-expr p) (parse-or p))

  (define (parse-or p)
    (let loop ([left (parse-and p)])
      (if (accept-keyword! p 'or) (loop (list 'bin 'or left (parse-and p))) left)))

  (define (parse-and p)
    (let loop ([left (parse-not p)])
      (if (accept-keyword! p 'and) (loop (list 'bin 'and left (parse-not p))) left)))

  (define (parse-not p)
    (if (accept-keyword! p 'not) (list 'not (parse-not p)) (parse-equality p)))

  (define (parse-equality p)
    (let loop ([left (parse-comparison p)])
      (cond [(accept-keyword! p 'is)
             (let ([op (if (accept-keyword! p 'not) 'is-not 'is)])
               (loop (list 'bin op left (parse-comparison p))))]
            [(or (at-op? p '=) (at-op? p '!=))
             (let ([op (token-value (next! p))])
               (loop (list 'bin op left (parse-comparison p))))]
            [(postfix-keyword? (if (at-keyword? p 'not) (peek-at p 1) (peek p)))
             (loop (parse-postfix p left))]
            [else left])))

  (define (postfix-keyword? t)
    (and t (eq? (token-kind t) 'keyword) (memq (token-value t) '(in like between)) #t))

  ;; [NOT] IN (...) | LIKE pattern | BETWEEN low AND high, after the left operand.
  (define (parse-postfix p left)
    (let ([negated? (accept-keyword! p 'not)])
      (cond [(accept-keyword! p 'in)
             (expect-op! p 'lparen)
             (cond [(at-query-start? p)
                    (let ([sel (parse-query p)])
                      (expect-op! p 'rparen)
                      (list 'in-select negated? left sel))]
                   [else
                    (let ([items (if (accept-op! p 'rparen)
                                     '()
                                     (let ([items (parse-comma-list p parse-expr)])
                                       (expect-op! p 'rparen)
                                       items))])
                      (list 'in negated? left items))])]
            [(accept-keyword! p 'like) (list 'like negated? left (parse-comparison p))]
            [else
             (expect-keyword! p 'between)
             (let ([low (parse-comparison p)])
               (expect-keyword! p 'and)
               (list 'between negated? left low (parse-comparison p)))])))

  (define (parse-comparison p)
    (parse-binary-level p parse-additive '((< . <) (<= . <=) (> . >) (>= . >=))))
  (define (parse-additive p)
    (parse-binary-level p parse-multiplicative '((+ . +) (- . -))))
  (define (parse-multiplicative p)
    (parse-binary-level p parse-concat '((* . *) (/ . /) (% . %))))
  (define (parse-concat p)
    (parse-binary-level p parse-unary '((concat . concat))))

  (define (parse-unary p)
    (cond [(accept-op! p '-)
           (let ([t (peek p)])
             (if (and t (eq? (token-kind t) 'int) (= (token-value t) (- int64-min)))
                 (begin (advance! p) (list 'lit int64-min))   ; the one literal that needs the sign
                 (list 'neg (parse-unary p))))]
          [(accept-op! p '+) (list 'pos (parse-unary p))]
          [else (parse-collate-suffix p (parse-primary p))]))

  ;; `e COLLATE name` binds tighter than any binary operator (7.2).
  (define (parse-collate-suffix p e)
    (if (accept-keyword! p 'collate)
        (parse-collate-suffix p (list 'collate e (expect-ident! p)))
        e))

  (define (parse-primary p)
    (let ([t (next! p)])
      (case (token-kind t)
        [(int) (list 'lit (normalize-integer (token-value t)))]
        [(real string) (list 'lit (token-value t))]
        [(keyword) (case (token-value t)
                     [(null) (list 'lit sql-null)]
                     [(case) (parse-case p)]
                     [(cast) (parse-cast p)]
                     [(exists) (expect-op! p 'lparen)
                               (let ([sel (parse-query p)]) (expect-op! p 'rparen) (list 'exists sel))]
                     [else (syntax-error)])]
        [(op) (cond [(not (eq? (token-value t) 'lparen)) (syntax-error)]
                    [(at-query-start? p)
                     (let ([sel (parse-query p)]) (expect-op! p 'rparen) (list 'subquery sel))]
                    [else (let ([e (parse-expr p)]) (expect-op! p 'rparen) e)])]
        [(ident)
         (cond [(accept-op! p 'lparen)
                (let ([call (parse-call p (token-value t))])
                  (if (accept-keyword! p 'over) (parse-over p call) call))]
               [(accept-op! p 'dot) (list 'col (token-value t) (expect-ident! p))]
               [else (list 'col #f (token-value t))])]
        [else (syntax-error)])))

  ;; After CASE: [operand] WHEN c THEN r ... [ELSE e] END
  (define (parse-case p)
    (let* ([operand (and (not (at-keyword? p 'when)) (parse-expr p))]
           [whens (let loop ([acc '()])
                    (if (accept-keyword! p 'when)
                        (let ([c (parse-expr p)])
                          (expect-keyword! p 'then)
                          (loop (cons (cons c (parse-expr p)) acc)))
                        (if (null? acc) (syntax-error) (reverse acc))))]
           [else-expr (and (accept-keyword! p 'else) (parse-expr p))])
      (expect-keyword! p 'end)
      (list 'case operand whens else-expr)))

  ;; After CAST: ( expr AS type )
  (define (parse-cast p)
    (expect-op! p 'lparen)
    (let ([e (parse-expr p)])
      (expect-keyword! p 'as)
      (let ([type (parse-type-name p)])
        (expect-op! p 'rparen)
        (list 'cast e type))))

  ;; INTEGER, REAL or TEXT, as a symbol.
  (define (parse-type-name p)
    (let ([word (and (at-ident? p) (token-lname (next! p)))])
      (cond [(assoc word '(("integer" . integer) ("real" . real) ("text" . text))) => cdr]
            [else (syntax-error)])))

  ;; After "name (": (call name args distinct? order star?), through the closing parenthesis.
  (define (parse-call p name)
    (cond [(accept-op! p '*) (expect-op! p 'rparen) (list 'call name '() #f '() #t)]
          [(accept-op! p 'rparen) (list 'call name '() #f '() #f)]
          [else
           (let* ([distinct? (accept-keyword! p 'distinct)]
                  [args (parse-comma-list p parse-expr)]
                  [order (if (accept-keyword! p 'order)
                             (begin (expect-keyword! p 'by) (parse-comma-list p parse-order-term))
                             '())])
             (expect-op! p 'rparen)
             (list 'call name args distinct? order #f))]))

;; After `call OVER`: a window name or a parenthesized window-spec (spec 6.1).
  (define (parse-over p call)
    (let ([over (if (accept-op! p 'lparen)
                    (let ([spec (parse-window-spec p)]) (expect-op! p 'rparen) spec)
                    (expect-ident! p))])
      ;; call = (call name args distinct? order star?)
      (list 'window-call (cadr call) (caddr call) (list-ref call 5) over)))

  ;; [base] [PARTITION BY ...] [ORDER BY ...] [frame], up to the closing parenthesis.
  (define (parse-window-spec p)
    (let* ([base (and (at-ident? p) (expect-ident! p))]
           [partition (if (accept-keyword! p 'partition)
                          (begin (expect-keyword! p 'by) (parse-comma-list p parse-expr))
                          '())]
           [order (if (accept-keyword! p 'order)
                      (begin (expect-keyword! p 'by) (parse-comma-list p parse-order-term))
                      '())]
           [frame (cond [(accept-keyword! p 'rows) (parse-frame p 'rows)]
                        [(accept-keyword! p 'range) (parse-frame p 'range)]
                        [else #f])])
      (list 'window base partition order frame)))

  ;; After ROWS / RANGE: bound | BETWEEN bound AND bound; a lone bound ends at CURRENT ROW.
  (define (parse-frame p mode)
    (if (accept-keyword! p 'between)
        (let ([start (parse-frame-bound p)])
          (expect-keyword! p 'and)
          (list mode start (parse-frame-bound p)))
        (list mode (parse-frame-bound p) (list 'current))))

  (define (parse-frame-bound p)
    (cond [(accept-keyword! p 'unbounded)
           (cond [(accept-keyword! p 'preceding) (list 'unbounded-preceding)]
                 [else (expect-keyword! p 'following) (list 'unbounded-following)])]
          [(accept-keyword! p 'current) (expect-keyword! p 'row) (list 'current)]
          [else
           (let* ([negative? (accept-op! p '-)]
                  [t (next! p)])
             (unless (memq (token-kind t) '(int real)) (syntax-error))
             (let ([n (if negative? (- (token-value t)) (token-value t))])
               (cond [(accept-keyword! p 'preceding) (list 'preceding n)]
                     [else (expect-keyword! p 'following) (list 'following n)])))]))

  ;; WINDOW name AS ( window-spec ), ...  (after WINDOW)
  (define (parse-window-clause p)
    (parse-comma-list p (lambda (p)
                          (let ([name (expect-ident! p)])
                            (expect-keyword! p 'as)
                            (expect-op! p 'lparen)
                            (let ([spec (parse-window-spec p)])
                              (expect-op! p 'rparen)
                              (cons name spec))))))

  ;; One or more items separated by commas.
  (define (parse-comma-list p parse-item)
    (let loop ([items (list (parse-item p))])
      (if (accept-op! p 'comma) (loop (cons (parse-item p) items)) (reverse items))))

  ;;; ---- SELECT --------------------------------------------------------------

  (define (parse-select-item p)
    (cond
      [(accept-op! p '*) 'star]
      [(and (at-ident? p) (token-is? (peek-at p 1) 'op 'dot) (token-is? (peek-at p 2) 'op '*))
       (let ([q (expect-ident! p)]) (advance! p) (advance! p) (make-qualified-star q))]
      [else
        (let* ([e (parse-expr p)]
               [alias (cond [(accept-keyword! p 'as) (expect-ident! p)]
                            [(at-ident? p) (expect-ident! p)]
                            [else #f])])
          (make-select-item e alias))]))

  ;; [AS] alias, or #f.
  (define (parse-optional-alias p)
    (cond [(accept-keyword! p 'as) (expect-ident! p)]
          [(at-ident? p) (expect-ident! p)]
          [else #f]))

  ;; table [[AS] alias] | ( select ) [[AS] alias]
  (define (parse-from-item p)
    (cond [(accept-op! p 'lparen)
           (let ([sel (parse-query p)])
             (expect-op! p 'rparen)
             (make-subquery-ref sel (parse-optional-alias p)))]
          [else (let ([name (expect-ident! p)]) (make-table-ref name (parse-optional-alias p)))]))

  ;; The join operator's kind (cross, inner or left), consuming it, or #f if none follows.
  (define (parse-join-op p)
    (cond [(accept-op! p 'comma) 'cross]
          [(accept-keyword! p 'join) 'inner]
          [(accept-keyword! p 'inner) (expect-keyword! p 'join) 'inner]
          [(accept-keyword! p 'cross) (expect-keyword! p 'join) 'cross]
          [(accept-keyword! p 'left) (accept-keyword! p 'outer) (expect-keyword! p 'join) 'left]
          [else #f]))

  ;; ON expr | USING ( column, ... ): (on . expr), (using . names) or #f.  A LEFT JOIN needs one,
  ;; `,` and CROSS JOIN take none.
  (define (parse-join-constraint p kind)
    (let ([constraint
           (cond [(eq? kind 'cross) #f]
                 [(accept-keyword! p 'on) (cons 'on (parse-expr p))]
                 [(accept-keyword! p 'using)
                  (expect-op! p 'lparen)
                  (let ([names (parse-comma-list p expect-ident!)])
                    (expect-op! p 'rparen)
                    (cons 'using names))]
                 [else #f])])
      (when (and (eq? kind 'left) (not constraint)) (syntax-error))
      constraint))

  (define (parse-from p)
    (let ([first (parse-from-item p)])
      (let loop ([joins '()])
        (let ([kind (parse-join-op p)])
          (if kind
              (let* ([item (parse-from-item p)]
                     [constraint (parse-join-constraint p kind)])
                (loop (cons (make-join-clause kind item constraint) joins)))
              (make-from-clause first (reverse joins)))))))

  (define (parse-order-term p)
    (let* ([e (parse-expr p)]
           [dir (cond [(accept-keyword! p 'desc) 'desc]
                      [else (accept-keyword! p 'asc) 'asc])]
           [nulls (and (accept-keyword! p 'nulls)
                       (cond [(accept-keyword! p 'first) 'first]
                             [(accept-keyword! p 'last) 'last]
                             [else (syntax-error)]))])
      (make-order-term e dir nulls)))

  ;; One simple SELECT, without ORDER BY / LIMIT (those belong to the whole query, 5.1).
  (define (parse-simple-select p)
    (expect-keyword! p 'select)
    (let* ([distinct (cond [(accept-keyword! p 'distinct) #t] [else (accept-keyword! p 'all) #f])]
           [items (parse-comma-list p parse-select-item)]
           [from (and (accept-keyword! p 'from) (parse-from p))]
           [where (and (accept-keyword! p 'where) (parse-expr p))]
           [group (and (accept-keyword! p 'group)
                       (begin (expect-keyword! p 'by) (parse-comma-list p parse-expr)))]
           [having (and (accept-keyword! p 'having) (parse-expr p))]
           [windows (if (accept-keyword! p 'window) (parse-window-clause p) '())])
      (make-select-stmt items distinct from where (or group '()) having '() #f #f #f windows)))

  (define (at-query-start? p) (or (at-keyword? p 'select) (at-keyword? p 'with)))

  ;; UNION [ALL] | INTERSECT | EXCEPT as a symbol, consuming it, or #f.
  (define (parse-compound-op p)
    (cond [(accept-keyword! p 'union) (if (accept-keyword! p 'all) 'union-all 'union)]
          [(accept-keyword! p 'intersect) 'intersect]
          [(accept-keyword! p 'except) 'except]
          [else #f]))

  ;; simple-select [compound-op simple-select]... [ORDER BY ...] [LIMIT ... [OFFSET ...]]
  (define (parse-compound-select p)
    (let* ([first (parse-simple-select p)]
           [rest (let loop ([acc '()])
                   (let ([op (parse-compound-op p)])
                     (if op (loop (cons (cons op (parse-simple-select p)) acc)) (reverse acc))))]
           [order (or (and (accept-keyword! p 'order)
                           (begin (expect-keyword! p 'by) (parse-comma-list p parse-order-term)))
                      '())]
           [limit (and (accept-keyword! p 'limit) (parse-expr p))]
           [offset (and limit (accept-keyword! p 'offset) (parse-expr p))])
      (if (null? rest)
          (make-select-stmt (select-stmt-items first) (select-stmt-distinct first) (select-stmt-from first)
                            (select-stmt-where first) (select-stmt-group-by first) (select-stmt-having first)
                            order limit offset #f (select-stmt-windows first))
          (make-compound-stmt first rest order limit offset #f))))

  ;; WITH [RECURSIVE] name [(column, ...)] AS ( query ), ...
  (define (parse-with p)
    (expect-keyword! p 'with)
    (let ([recursive (accept-keyword! p 'recursive)])
      (make-with-clause
       recursive
       (parse-comma-list
        p (lambda (p)
            (let* ([name (expect-ident! p)]
                   [columns (and (accept-op! p 'lparen)
                                 (let ([names (parse-comma-list p expect-ident!)])
                                   (expect-op! p 'rparen)
                                   names))])
              (expect-keyword! p 'as)
              (expect-op! p 'lparen)
              (let ([select (parse-query p)])
                (expect-op! p 'rparen)
                (make-cte name columns select))))))))

  ;; [WITH ...] select, a select-stmt or compound-stmt.
  (define (parse-query p)
    (let* ([with (and (at-keyword? p 'with) (parse-with p))]
           [q (parse-compound-select p)])
      (if with (query-attach-with q with) q)))

  ;;; ---- other statements ----------------------------------------------------

  ;; [+|-] number | string | NULL, as a value.
  (define (parse-default-value p)
    (let* ([sign (cond [(accept-op! p '-) '-] [(accept-op! p '+) '+] [else #f])]
           [t (next! p)]
           [negate (lambda (n) (if (eq? sign '-) (- n) n))])
      (case (token-kind t)
        [(int) (normalize-integer (negate (token-value t)))]
        [(real) (negate (token-value t))]
        [(string) (if sign (syntax-error) (token-value t))]
        [(keyword) (if (and (not sign) (eq? (token-value t) 'null)) sql-null (syntax-error))]
        [else (syntax-error)])))

  ;; name type [constraint]...   (COLLATE name may be among the constraints, 7.2)
  (define (parse-column-def p)
    (let* ([name (expect-ident! p)]
           [type (parse-type-name p)])
      (let loop ([not-null #f] [unique #f] [primary #f] [default sql-null] [collation #f])
        (cond [(accept-keyword! p 'primary) (expect-keyword! p 'key) (loop not-null unique #t default collation)]
              [(accept-keyword! p 'not) (expect-keyword! p 'null) (loop #t unique primary default collation)]
              [(accept-keyword! p 'unique) (loop not-null #t primary default collation)]
              [(accept-keyword! p 'default)
               (loop not-null unique primary (parse-default-value p) collation)]
              [(accept-keyword! p 'collate)
               (loop not-null unique primary default (expect-ident! p))]
              [else (make-column-def name type not-null unique primary default collation)]))))

  ;; PRIMARY KEY ( c, ... ) | UNIQUE ( c, ... ), or #f when none follows.
  (define (parse-table-constraint p)
    (let ([kind (cond [(accept-keyword! p 'primary) (expect-keyword! p 'key) 'primary]
                      [(accept-keyword! p 'unique) 'unique]
                      [else #f])])
      (and kind
           (begin (expect-op! p 'lparen)
                  (let ([names (parse-comma-list p expect-ident!)])
                    (expect-op! p 'rparen)
                    (make-table-constraint kind names))))))

  ;; Column definitions, then table constraints: (values defs constraints).
  (define (parse-create-items p)
    (let loop ([defs '()] [constraints '()])
      (let* ([constraint (parse-table-constraint p)]
             [defs (if constraint
                       defs
                       (if (null? constraints) (cons (parse-column-def p) defs) (syntax-error)))]
             [constraints (if constraint (cons constraint constraints) constraints)])
        (if (accept-op! p 'comma)
            (loop defs constraints)
            (if (null? defs) (syntax-error) (values (reverse defs) (reverse constraints)))))))

  (define (parse-if-not-exists p)
    (and (accept-keyword! p 'if) (begin (expect-keyword! p 'not) (expect-keyword! p 'exists) #t)))
  (define (parse-if-exists p)
    (and (accept-keyword! p 'if) (begin (expect-keyword! p 'exists) #t)))

  (define (parse-parenthesized-names p)
    (expect-op! p 'lparen)
    (let ([names (parse-comma-list p expect-ident!)])
      (expect-op! p 'rparen)
      names))

  (define (parse-create-table p)
    (let* ([if-not-exists (parse-if-not-exists p)]
           [name (expect-ident! p)])
      (expect-op! p 'lparen)
      (let-values ([(defs constraints) (parse-create-items p)])
        (expect-op! p 'rparen)
        (make-create-table-stmt name if-not-exists defs constraints))))

  ;; CREATE VIEW [IF NOT EXISTS] name [(column, ...)] AS query
  (define (parse-create-view p)
    (let* ([if-not-exists (parse-if-not-exists p)]
           [name (expect-ident! p)]
           [columns (and (at-op? p 'lparen) (parse-parenthesized-names p))])
      (expect-keyword! p 'as)
      (make-create-view-stmt name if-not-exists columns (parse-query p))))

  ;; column [COLLATE name]: (column . collation-name-or-#f)
  (define (parse-indexed-column p)
    (let* ([column (expect-ident! p)]
           [collation (and (accept-keyword! p 'collate) (expect-ident! p))])
      (cons column collation)))

  ;; CREATE [UNIQUE] INDEX [IF NOT EXISTS] name ON table (column [COLLATE name], ...)   (after INDEX)
  (define (parse-create-index p unique)
    (let* ([if-not-exists (parse-if-not-exists p)]
           [name (expect-ident! p)]
           [table (begin (expect-keyword! p 'on) (expect-ident! p))]
           [entries (begin (expect-op! p 'lparen)
                           (let ([entries (parse-comma-list p parse-indexed-column)])
                             (expect-op! p 'rparen)
                             entries))])
      (make-create-index-stmt name unique if-not-exists table (map car entries) (map cdr entries))))

  (define (parse-create p)
    (cond [(accept-keyword! p 'table) (parse-create-table p)]
          [(accept-keyword! p 'view) (parse-create-view p)]
          [(accept-keyword! p 'index) (parse-create-index p #f)]
          [(accept-keyword! p 'unique) (expect-keyword! p 'index) (parse-create-index p #t)]
          [else (syntax-error)]))

  (define (parse-drop p)
    (let* ([kind (cond [(accept-keyword! p 'table) 'table]
                       [(accept-keyword! p 'view) 'view]
                       [(accept-keyword! p 'index) 'index]
                       [else (syntax-error)])]
           [if-exists (parse-if-exists p)]
           [name (expect-ident! p)])
      (case kind
        [(table) (make-drop-table-stmt name if-exists)]
        [(view) (make-drop-view-stmt name if-exists)]
        [else (make-drop-index-stmt name if-exists)])))

  ;; ALTER TABLE t ADD [COLUMN] def | RENAME TO name | RENAME [COLUMN] c TO name   (after ALTER)
  (define (parse-alter p)
    (expect-keyword! p 'table)
    (let ([table (expect-ident! p)])
      (cond [(accept-keyword! p 'add)
             (accept-keyword! p 'column)
             (make-alter-add-column-stmt table (parse-column-def p))]
            [(accept-keyword! p 'rename)
             (if (accept-keyword! p 'to)
                 (make-alter-rename-table-stmt table (expect-ident! p))
                 (begin (accept-keyword! p 'column)
                        (let ([column (expect-ident! p)])
                          (expect-keyword! p 'to)
                          (make-alter-rename-column-stmt table column (expect-ident! p)))))]
            [else (syntax-error)])))

  ;; BEGIN | COMMIT | END | ROLLBACK, then an optional TRANSACTION.
  (define (parse-transaction p action)
    (accept-keyword! p 'transaction)
    (make-transaction-stmt action))

  (define (parse-value-row p)
    (expect-op! p 'lparen)
    (let ([row (parse-comma-list p parse-expr)])
      (expect-op! p 'rparen)
      row))

  (define (parse-insert p)
    (expect-keyword! p 'into)
    (let* ([table (expect-ident! p)]
           [columns (and (accept-op! p 'lparen)
                         (let ([names (parse-comma-list p expect-ident!)])
                           (expect-op! p 'rparen)
                           names))])
      (if (accept-keyword! p 'values)
          (make-insert-stmt table columns (parse-comma-list p parse-value-row) #f)
          (make-insert-stmt table columns #f (parse-query p)))))

  ;; UPDATE table SET column = expr, ... [WHERE expr]
  (define (parse-update p)
    (let* ([table (expect-ident! p)]
           [assignments (begin (expect-keyword! p 'set)
                               (parse-comma-list p (lambda (p)
                                                     (let ([column (expect-ident! p)])
                                                       (expect-op! p '=)
                                                       (cons column (parse-expr p))))))]
           [where (and (accept-keyword! p 'where) (parse-expr p))])
      (make-update-stmt table assignments where)))

  ;; DELETE FROM table [WHERE expr]
  (define (parse-delete p)
    (expect-keyword! p 'from)
    (let* ([table (expect-ident! p)]
           [where (and (accept-keyword! p 'where) (parse-expr p))])
      (make-delete-stmt table where)))

  (define (parse-keyword-statement p)
    (let ([t (next! p)])
      (cond [(token-is? t 'keyword 'select) (retreat! p) (parse-query p)]
            [(token-is? t 'keyword 'insert) (parse-insert p)]
            [(token-is? t 'keyword 'create) (parse-create p)]
            [(token-is? t 'keyword 'drop) (parse-drop p)]
            [(token-is? t 'keyword 'update) (parse-update p)]
            [(token-is? t 'keyword 'delete) (parse-delete p)]
            [(token-is? t 'keyword 'alter) (parse-alter p)]
            [(token-is? t 'keyword 'begin) (parse-transaction p 'begin)]
            [(token-is? t 'keyword 'commit) (parse-transaction p 'commit)]
            [(token-is? t 'keyword 'end) (parse-transaction p 'commit)]
            [(token-is? t 'keyword 'rollback) (parse-transaction p 'rollback)]
            [else (syntax-error)])))

  ;; WITH ... followed by a select or an INSERT ... SELECT that the ctes belong to.
  (define (parse-with-statement p)
    (let ([with (parse-with p)])
      (cond [(accept-keyword! p 'insert)
             (let ([stmt (parse-insert p)])
               (if (insert-stmt-query stmt)
                   (make-insert-stmt (insert-stmt-table stmt) (insert-stmt-columns stmt) #f
                                     (query-attach-with (insert-stmt-query stmt) with))
                   stmt))]
            [else (query-attach-with (parse-compound-select p) with)])))

  ;;; ---- entry point -----------------------------------------------------------

  ;; A statement record, or #f for an empty statement.
  (define (parse-statement tokens)
    (if (null? tokens)
        #f
        (let* ([p (make-cursor (list->vector tokens) 0)]
               [stmt (if (at-keyword? p 'with) (parse-with-statement p) (parse-keyword-statement p))])
          (when (peek p) (syntax-error))
          stmt))))
