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
             (let ([items (if (accept-op! p 'rparen)
                              '()
                              (let ([items (parse-comma-list p parse-expr)])
                                (expect-op! p 'rparen)
                                items))])
               (list 'in negated? left items))]
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
          [else (parse-primary p)]))

  (define (parse-primary p)
    (let ([t (next! p)])
      (case (token-kind t)
        [(int) (list 'lit (normalize-integer (token-value t)))]
        [(real string) (list 'lit (token-value t))]
        [(keyword) (case (token-value t)
                     [(null) (list 'lit sql-null)]
                     [(case) (parse-case p)]
                     [(cast) (parse-cast p)]
                     [else (syntax-error)])]
        [(op) (if (eq? (token-value t) 'lparen)
                  (let ([e (parse-expr p)]) (expect-op! p 'rparen) e)
                  (syntax-error))]
        [(ident)
         (cond [(accept-op! p 'lparen) (list 'call (token-value t) (parse-call-arguments p))]
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

  ;; After "name (": the arguments and the closing parenthesis.
  (define (parse-call-arguments p)
    (if (accept-op! p 'rparen)
        '()
        (let loop ([args (list (parse-expr p))])
          (cond [(accept-op! p 'comma) (loop (cons (parse-expr p) args))]
                [else (expect-op! p 'rparen) (reverse args)]))))

  ;; One or more items separated by commas.
  (define (parse-comma-list p parse-item)
    (let loop ([items (list (parse-item p))])
      (if (accept-op! p 'comma) (loop (cons (parse-item p) items)) (reverse items))))

  ;;; ---- SELECT --------------------------------------------------------------

  (define (parse-select-item p)
    (if (accept-op! p '*)
        'star
        (let* ([e (parse-expr p)]
               [alias (cond [(accept-keyword! p 'as) (expect-ident! p)]
                            [(at-ident? p) (expect-ident! p)]
                            [else #f])])
          (make-select-item e alias))))

  (define (parse-order-term p)
    (let* ([e (parse-expr p)]
           [dir (cond [(accept-keyword! p 'desc) 'desc]
                      [else (accept-keyword! p 'asc) 'asc])]
           [nulls (and (accept-keyword! p 'nulls)
                       (cond [(accept-keyword! p 'first) 'first]
                             [(accept-keyword! p 'last) 'last]
                             [else (syntax-error)]))])
      (make-order-term e dir nulls)))

  (define (parse-select p)
    (let* ([items (parse-comma-list p parse-select-item)]
           [from (and (accept-keyword! p 'from) (expect-ident! p))]
           [where (and (accept-keyword! p 'where) (parse-expr p))]
           [order (and (accept-keyword! p 'order)
                       (begin (expect-keyword! p 'by) (parse-comma-list p parse-order-term)))]
           [limit (and (accept-keyword! p 'limit) (parse-expr p))]
           [offset (and limit (accept-keyword! p 'offset) (parse-expr p))])
      (make-select-stmt items from where (or order '()) limit offset)))

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

  ;; name type [constraint]...
  (define (parse-column-def p)
    (let* ([name (expect-ident! p)]
           [type (parse-type-name p)])
      (let loop ([not-null #f] [unique #f] [primary #f] [default sql-null])
        (cond [(accept-keyword! p 'primary) (expect-keyword! p 'key) (loop not-null unique #t default)]
              [(accept-keyword! p 'not) (expect-keyword! p 'null) (loop #t unique primary default)]
              [(accept-keyword! p 'unique) (loop not-null #t primary default)]
              [(accept-keyword! p 'default) (loop not-null unique primary (parse-default-value p))]
              [else (make-column-def name type not-null unique primary default)]))))

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

  (define (parse-create p)
    (expect-keyword! p 'table)
    (let* ([if-not-exists (and (accept-keyword! p 'if)
                               (begin (expect-keyword! p 'not) (expect-keyword! p 'exists) #t))]
           [name (expect-ident! p)])
      (expect-op! p 'lparen)
      (let-values ([(defs constraints) (parse-create-items p)])
        (expect-op! p 'rparen)
        (make-create-table-stmt name if-not-exists defs constraints))))

  (define (parse-drop p)
    (expect-keyword! p 'table)
    (let* ([if-exists (and (accept-keyword! p 'if) (begin (expect-keyword! p 'exists) #t))]
           [name (expect-ident! p)])
      (make-drop-table-stmt name if-exists)))

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
      (expect-keyword! p 'values)
      (make-insert-stmt table columns (parse-comma-list p parse-value-row))))

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

  ;;; ---- entry point -----------------------------------------------------------

  ;; A statement record, or #f for an empty statement.
  (define (parse-statement tokens)
    (if (null? tokens)
        #f
        (let* ([p (make-cursor (list->vector tokens) 0)]
               [t (next! p)]
               [stmt (cond [(token-is? t 'keyword 'select) (parse-select p)]
                           [(token-is? t 'keyword 'insert) (parse-insert p)]
                           [(token-is? t 'keyword 'create) (parse-create p)]
                           [(token-is? t 'keyword 'drop) (parse-drop p)]
                           [(token-is? t 'keyword 'update) (parse-update p)]
                           [(token-is? t 'keyword 'delete) (parse-delete p)]
                           [else (syntax-error)])])
          (when (peek p) (syntax-error))
          stmt))))
