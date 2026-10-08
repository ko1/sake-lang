;;; Parsing (1.4 - 1.8): a statement's tokens into the syntax tree of (engine ast).
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
            [else (raise-syntax-error)])))

  (define (parse-create p)
    (expect-kw! p 'table)
    (let* ([if-not-exists (and (accept-kw! p 'if)
                               (begin (expect-kw! p 'not) (expect-kw! p 'exists) #t))]
           [name (expect-name! p)])
      (expect-op! p "(")
      (let ([columns (parse-comma-list p parse-column-def)])
        (expect-op! p ")")
        (make-create-table name if-not-exists columns))))

  (define (parse-column-def p)
    (let* ([name (expect-name! p)]
           [type (expect-name! p)]
           [sym (cond [(string=? (name-lower type) "integer") 'integer]
                      [(string=? (name-lower type) "real") 'real]
                      [(string=? (name-lower type) "text") 'text]
                      [else (raise-syntax-error)])])
      (make-column-def name sym)))

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
    (let* ([items (parse-comma-list p parse-result-column)]
           [from (and (accept-kw! p 'from) (expect-name! p))]
           [where (and (accept-kw! p 'where) (parse-expr p))]
           [order (if (accept-kw! p 'order)
                      (begin (expect-kw! p 'by) (parse-comma-list p parse-order-term))
                      '())]
           [limit (and (accept-kw! p 'limit) (parse-expr p))]
           [offset (and limit (accept-kw! p 'offset) (parse-expr p))])
      (make-select-stmt items from where order limit offset)))

  (define (parse-result-column p)
    (if (accept-op! p "*")
        (make-result-column 'star #f)
        (let* ([expr (parse-expr p)]
               [alias (cond [(accept-kw! p 'as) (expect-name! p)]
                            [(and (peek p) (eq? (token-kind (peek p)) 'ident)) (expect-name! p)]
                            [else #f])])
          (make-result-column expr alias))))

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
          [else left]))))

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
               [else (raise-syntax-error)])]
        [(ident)
         (if (op? (peek-at p 1) "(")
             (parse-call p)
             (list 'col (expect-name! p)))]
        [(op)
         (if (op? t "(")
             (begin (advance! p)
                    (let ([e (parse-expr p)]) (expect-op! p ")") e))
             (raise-syntax-error))]
        [else (raise-syntax-error)])))

  (define (parse-call p)
    (let ([name (expect-name! p)])
      (expect-op! p "(")
      (if (accept-op! p ")")
          (list 'call name '())
          (let ([args (parse-comma-list p parse-expr)])
            (expect-op! p ")")
            (list 'call name args))))))
