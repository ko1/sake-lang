;;; (engine compound) -- UNION / INTERSECT / EXCEPT chains (spec 5.1).
;;;
;;; The parts are planned by the caller's `plan-part` (a simple select to a plan); this
;;; library checks their widths, combines their rows left to right, and applies the trailing
;;; ORDER BY / LIMIT / OFFSET to the whole.
(library (engine compound)
  (export plan-compound make-compound-plan check-width! compound-collations)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine plan)
          (engine ordering) (engine grouping) (engine paging))

  (define (op-text op)
    (case op [(union) "UNION"] [(union-all) "UNION ALL"] [(intersect) "INTERSECT"] [else "EXCEPT"]))

  ;; For each column of a compound select over `plans`, #f or (implicit . collation): that of
  ;; the first part, left to right, whose column has a collation (7.4).
  (define (compound-collation-entries plans)
    (apply map
           (lambda entries
             (let ([found (find values entries)])
               (and found (cons 'implicit (cdr found)))))
           (map plan-collations plans)))

  ;; The collation rows of the compound are compared under, per column (binary if none has one).
  (define (compound-collations plans)
    (map (lambda (entry) (if entry (cdr entry) 'binary)) (compound-collation-entries plans)))

  ;; The result rows of `left op right`, rows compared column by column under `colls`.
  ;; INTERSECT and EXCEPT keep distinct rows of `left`.
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

  ;; The result column an ORDER BY term of a compound select means: (index . collation), the
  ;; collation being that of a COLLATE following the term, or #f.
  (define (order-column term position plans width)
    (let-values ([(expr override) (split-collate (order-term-expr term))])
      (let ([k (position-term expr)])
        (cons
         (cond
           [k (unless (<= 1 k width)
                (raise-sql-error (string-append (ordinal position)
                                                " ORDER BY term out of range - should be between 1 and "
                                                (number->string width))))
              (- k 1)]
           [(and (eq? (car expr) 'col) (not (cadr expr))
                 (find-column-named plans (ascii-downcase (caddr expr))))
            => values]
           [else (raise-sql-error (string-append (ordinal position)
                                                 " ORDER BY term does not match any column in the result set"))])
         override))))

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
           [targets (let loop ([terms terms] [i 1])
                      (if (null? terms)
                          '()
                          (cons (order-column (car terms) i plans width) (loop (cdr terms) (+ i 1)))))]
           [columns (map car targets)]
           [column-colls (compound-collations plans)]
           [term-colls (map (lambda (t) (or (cdr t) (list-ref column-colls (car t)))) targets)]
           [limit (and (compound-stmt-limit stmt) (constant-integer db (compound-stmt-limit stmt)))]
           [offset (if (compound-stmt-offset stmt) (constant-integer db (compound-stmt-offset stmt)) 0)]
           [stop-after (and limit (>= limit 0) (null? terms) (+ limit offset))])
      (make-plan
       (plan-names (car plans))
       (plan-affinities (car plans))
       (compound-collation-entries plans)
       (exists plan-correlated? plans)
       (lambda ()
         (let* ([rows (rows-of stop-after)]
                [sorted (if (null? terms)
                            rows
                            (list-sort (lambda (a b)
                                         (< (compare-keys terms term-colls
                                                          (map (lambda (c) (vector-ref a c)) columns)
                                                          (map (lambda (c) (vector-ref b c)) columns))
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
           [colls (compound-collations (cons first rest))])
      (make-compound-plan
       db stmt (cons first rest)
       (lambda (stop-after)
         (let loop ([acc ((plan-run first))] [ops ops] [rest rest])
           (if (null? ops)
               acc
               (loop (combine-rows (car ops) acc ((plan-run (car rest))) colls) (cdr ops) (cdr rest))))))))
)
