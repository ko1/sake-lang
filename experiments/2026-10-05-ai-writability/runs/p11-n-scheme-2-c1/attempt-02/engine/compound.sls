;;; (engine compound) -- UNION / INTERSECT / EXCEPT chains (spec 5.1).
;;;
;;; The parts are planned by the caller's `plan-part` (a simple select to a plan); this
;;; library checks their widths, combines their rows left to right, and applies the trailing
;;; ORDER BY / LIMIT / OFFSET to the whole.
(library (engine compound)
  (export plan-compound make-compound-plan check-width!)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine plan)
          (engine ordering) (engine grouping) (engine paging) (only (engine catalog) lookup-collation))

  (define (op-text op)
    (case op [(union) "UNION"] [(union-all) "UNION ALL"] [(intersect) "INTERSECT"] [else "EXCEPT"]))

  ;; The result rows of `left op right`, text compared under `colls` (a collation symbol per
  ;; column).  INTERSECT and EXCEPT keep distinct rows of `left`.
  (define (combine-rows op left right colls)
    (let ([seen (make-row-set colls)])
      (case op
        [(union-all) (append left right)]
        [(union) (filter (lambda (row) (row-set-add! seen row)) (append left right))]
        [else
         (let ([in-right (make-row-set colls)] [keep-if-in? (eq? op 'intersect)])
           (for-each (lambda (row) (row-set-add! in-right row)) right)
           (filter (lambda (row)
                     (and (eq? (row-set-contains? in-right row) keep-if-in?)
                          (row-set-add! seen row)))
                   left))])))

  ;; Index of the first column, over the parts' names in order, that is named `lname`, or #f.
  (define (find-column-named plans lname)
    (let loop ([plans plans])
      (and (pair? plans)
           (or (let find ([names (plan-names (car plans))] [i 0])
                 (cond [(null? names) #f]
                       [(and (car names) (string=? (ascii-downcase (car names)) lname)) i]
                       [else (find (cdr names) (+ i 1))]))
               (loop (cdr plans))))))

  ;; For each result column of a compound: the collation (7.4) of the first part, left to right,
  ;; that gives that column one -- #f (none), (explicit . symbol) or (implicit . symbol).
  (define (compound-collations plans)
    (apply map (lambda column-collations (find values column-collations))
           (map plan-collations plans)))

  (define (collation-symbols collations)
    (map (lambda (c) (if c (cdr c) 'binary)) collations))

  ;; The result column an ORDER BY term of a compound select means, and the collation it sorts
  ;; under: (index . collation-symbol).  `colls`: the compound's column collation symbols.
  (define (order-column term position plans width colls)
    (let* ([full (order-term-expr term)]
           [collate? (eq? (car full) 'collate)]
           [explicit (and collate? (lookup-collation (caddr full)))]
           [expr (if collate? (cadr full) full)]
           [k (position-term expr)])
      (define (column index) (cons index (or explicit (list-ref colls index))))
      (cond
        [k (unless (<= 1 k width)
             (raise-sql-error (string-append (ordinal position)
                                             " ORDER BY term out of range - should be between 1 and "
                                             (number->string width))))
           (column (- k 1))]
        [(and (eq? (car expr) 'col) (not (cadr expr))
              (find-column-named plans (ascii-downcase (caddr expr))))
         => column]
        [else (raise-sql-error (string-append (ordinal position)
                                              " ORDER BY term does not match any column in the result set"))])))

  (define (check-width! op width plan)
    (unless (= width (length (plan-names plan)))
      (raise-sql-error
       (string-append "SELECTs to the left and right of " (op-text op)
                      " do not have the same number of result columns"))))

  ;; The plan of a compound select over the plans of its parts (the first names the
  ;; columns).  rows-of: (stop-after) -> the combined rows before ORDER BY, where stop-after
  ;; is #f or a count after which more rows cannot matter (LIMIT without ORDER BY).
  (define (make-compound-plan db stmt plans rows-of)
    (let* ([width (length (plan-names (car plans)))]
           [terms (compound-stmt-order-by stmt)]
           [collations (compound-collations plans)]
           [columns (let loop ([terms terms] [i 1])   ; each (index . collation-symbol)
                      (if (null? terms)
                          '()
                          (cons (order-column (car terms) i plans width (collation-symbols collations))
                                (loop (cdr terms) (+ i 1)))))]
           [limit (and (compound-stmt-limit stmt) (constant-integer db (compound-stmt-limit stmt)))]
           [offset (if (compound-stmt-offset stmt) (constant-integer db (compound-stmt-offset stmt)) 0)]
           [stop-after (and limit (>= limit 0) (null? terms) (+ limit offset))])
      (make-plan
       (plan-names (car plans))
       (plan-affinities (car plans))
       collations
       (exists plan-correlated? plans)
       (lambda ()
         (let* ([rows (rows-of stop-after)]
                [sorted (if (null? terms)
                            rows
                            (list-sort (lambda (a b)
                                         (< (compare-keys terms
                                                          (map (lambda (c) (collate-value (vector-ref a (car c)) (cdr c)))
                                                               columns)
                                                          (map (lambda (c) (collate-value (vector-ref b (car c)) (cdr c)))
                                                               columns))
                                            0))
                                       rows))])
           (page-rows sorted limit offset))))))

  ;; plan-part: a simple select -> its plan.
  (define (plan-compound db stmt plan-part)
    (let* ([first (plan-part (compound-stmt-first stmt))]
           [width (length (plan-names first))]
           [ops (map car (compound-stmt-rest stmt))]
           [rest (map (lambda (entry)
                        (let ([plan (plan-part (cdr entry))])
                          (check-width! (car entry) width plan)
                          plan))
                      (compound-stmt-rest stmt))]
           [colls (collation-symbols (compound-collations (cons first rest)))])
      (make-compound-plan
       db stmt (cons first rest)
       (lambda (stop-after)
         (let loop ([acc ((plan-run first))] [ops ops] [rest rest])
           (if (null? ops)
               acc
               (loop (combine-rows (car ops) acc ((plan-run (car rest))) colls) (cdr ops) (cdr rest))))))))
)
