;;; (engine select) -- running a SELECT statement (spec 1.7).
;;;
;;; run-select returns the result rows (vectors of values).  All name
;;; resolution happens while planning, before the first row is read.
(library (engine select)
  (export run-select)
  (import (rnrs) (engine errors) (engine values) (engine ast)
          (engine catalog) (engine expr) (only (chezscheme) iota))

  (define (no-scope) (make-scope #f '()))

  ;;; ---- result columns --------------------------------------------------------

  ;; List of (cexpr . alias-or-#f), with * expanded.
  (define (plan-result-columns items table)
    (let ([scope (make-scope table '())])
      (apply append
             (map (lambda (item)
                    (if (eq? item 'star)
                        (begin
                          (unless table (raise-sql-error "no tables specified"))
                          (let ([cols (table-columns table)])
                            (map (lambda (i)
                                   (let ([col (vector-ref cols i)])
                                     (cons (make-cexpr (lambda (row) (vector-ref row i)) (column-type col))
                                           #f)))
                                 (iota (vector-length cols)))))
                        (list (cons (compile-expr (select-item-expr item) scope)
                                    (select-item-alias item)))))
                  items))))

  ;; alist lower-cased alias -> (index . cexpr)
  (define (alias-table result-columns)
    (let loop ([cols result-columns] [i 0] [acc '()])
      (cond [(null? cols) (reverse acc)]
            [(cdar cols) (loop (cdr cols) (+ i 1)
                               (cons (cons (ascii-downcase (cdar cols)) (cons i (caar cols))) acc))]
            [else (loop (cdr cols) (+ i 1) acc)])))

  ;;; ---- ORDER BY ----------------------------------------------------------------

  (define (ordinal n)
    (let ([suffix (cond [(memv (mod n 100) '(11 12 13)) "th"]
                        [(= (mod n 10) 1) "st"]
                        [(= (mod n 10) 2) "nd"]
                        [(= (mod n 10) 3) "rd"]
                        [else "th"])])
      (string-append (number->string n) suffix)))

  ;; The k of an ORDER BY term that is an integer literal (or minus one), else #f.
  (define (position-term expr)
    (cond [(and (eq? (car expr) 'lit) (integer-value? (cadr expr))) (cadr expr)]
          [(and (eq? (car expr) 'neg) (eq? (car (cadr expr)) 'lit) (integer-value? (cadr (cadr expr))))
           (- (cadr (cadr expr)))]
          [else #f]))

  ;; A term becomes a procedure (input-row result-row) -> sort key value.
  (define (plan-order-term term position nresult aliases scope)
    (let* ([expr (order-term-expr term)]
           [k (position-term expr)]
           [alias (and (eq? (car expr) 'col) (not (cadr expr))
                       (assoc (ascii-downcase (caddr expr)) aliases))])
      (cond
        [k (unless (<= 1 k nresult)
             (raise-sql-error (string-append (ordinal position)
                                             " ORDER BY term out of range - should be between 1 and "
                                             (number->string nresult))))
           (lambda (row result) (vector-ref result (- k 1)))]
        [alias (let ([i (cadr alias)]) (lambda (row result) (vector-ref result i)))]
        [else (let ([p (cexpr-proc (compile-expr expr scope))])
                (lambda (row result) (p row)))])))

  ;; -1/0/1 comparing two key lists under the order terms.
  (define (compare-keys terms a b)
    (let loop ([terms terms] [a a] [b b])
      (if (null? terms)
          0
          (let* ([term (car terms)]
                 [desc? (eq? (order-term-direction term) 'desc)]
                 [nulls-first? (case (order-term-nulls term) [(first) #t] [(last) #f] [else (not desc?)])]
                 [x (car a)] [y (car b)]
                 [c (cond [(and (sql-null? x) (sql-null? y)) 0]
                          [(sql-null? x) (if nulls-first? -1 1)]
                          [(sql-null? y) (if nulls-first? 1 -1)]
                          [desc? (- (value-compare x y))]
                          [else (value-compare x y)])])
            (if (zero? c) (loop (cdr terms) (cdr a) (cdr b)) c)))))

  ;;; ---- LIMIT / OFFSET ---------------------------------------------------------------

  ;; The integer a LIMIT/OFFSET expression gives (no row in scope).
  (define (constant-integer expr)
    (let ([v ((cexpr-proc (compile-expr expr (no-scope))) (vector))])
      (cond [(sql-null? v) 0]
            [(string? v) (constant-integer-of (text->number-prefix v))]
            [else (constant-integer-of v)])))
  (define (constant-integer-of n) (if (integer-value? n) n (exact (truncate n))))

  (define (drop-rows rows n)
    (let loop ([rows rows] [n n]) (if (or (<= n 0) (null? rows)) rows (loop (cdr rows) (- n 1)))))
  (define (take-rows rows n)
    (let loop ([rows rows] [n n] [acc '()])
      (if (or (<= n 0) (null? rows)) (reverse acc) (loop (cdr rows) (- n 1) (cons (car rows) acc)))))

  ;;; ---- the statement ------------------------------------------------------------------

  (define (run-select db stmt)
    (let* ([from (select-stmt-from stmt)]
           [table (and from
                       (or (database-find-table db (ascii-downcase from))
                           (raise-sql-error (string-append "no such table: " from))))]
           [result-columns (plan-result-columns (select-stmt-items stmt) table)]
           [aliases (alias-table result-columns)]
           [scope (make-scope table aliases)]
           [result-procs (map (lambda (rc) (cexpr-proc (car rc))) result-columns)]
           [where (and (select-stmt-where stmt) (cexpr-proc (compile-expr (select-stmt-where stmt) scope)))]
           [terms (select-stmt-order-by stmt)]
           [key-procs (let loop ([ts terms] [i 1])
                        (if (null? ts)
                            '()
                            (cons (plan-order-term (car ts) i (length result-columns) aliases scope)
                                  (loop (cdr ts) (+ i 1)))))]
           [limit (and (select-stmt-limit stmt) (constant-integer (select-stmt-limit stmt)))]
           [offset (if (select-stmt-offset stmt) (constant-integer (select-stmt-offset stmt)) 0)]
           [input (if table (table-rows table) (list (vector)))]
           [kept (if where (filter (lambda (row) (eq? (truth (where row)) #t)) input) input)]
           ;; each entry: (sort-keys . result-row)
           [entries (map (lambda (row)
                           (let ([result (list->vector (map (lambda (p) (p row)) result-procs))])
                             (cons (map (lambda (kp) (kp row result)) key-procs) result)))
                         kept)]
           [sorted (if (null? terms)
                       entries
                       (list-sort (lambda (x y) (< (compare-keys terms (car x) (car y)) 0)) entries))]
           [paged (drop-rows (map cdr sorted) offset)])
      (if (and limit (>= limit 0)) (take-rows paged limit) paged))))
