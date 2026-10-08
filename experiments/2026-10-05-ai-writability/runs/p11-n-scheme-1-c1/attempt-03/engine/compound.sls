;;; Compound selects (5.1): UNION, UNION ALL, INTERSECT, EXCEPT, evaluated left to right, then the
;;; trailing ORDER BY / LIMIT / OFFSET on the whole result.
(library (engine compound)
  (export prepare-compound)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine scope)
          (engine orderby))

  (define (op-name op)
    (case op [(union) "UNION"] [(union-all) "UNION ALL"] [(intersect) "INTERSECT"] [else "EXCEPT"]))

  ;; prepare: the select planner. Returns what it does: the result columns (those of the first
  ;; simple-select) and a thunk giving the rows.
  (define (prepare-compound db stmt outer prepare)
    (let-values ([(cols0 run0) (prepare db (compound-first stmt) outer)])
      (let loop ([rest (compound-rest stmt)] [all-cols (list cols0)] [runs '()])
        (if (pair? rest)
            (let-values ([(cols run) (prepare db (cdr (car rest)) outer)])
              (unless (= (vector-length cols) (vector-length cols0))
                (raise-sql-error
                 (string-append "SELECTs to the left and right of " (op-name (car (car rest)))
                                " do not have the same number of result columns")))
              (loop (cdr rest) (cons cols all-cols) (cons run runs)))
            (finish db stmt outer cols0 run0 (reverse all-cols) (reverse runs))))))

  (define (finish db stmt outer cols0 run0 all-cols runs)
    (let* ([scope (make-scope db '() outer)]
           [colls (column-collations all-cols)]
           [terms (compile-compound-order-terms (compound-order stmt) all-cols colls)]
           [limit (compile-bound (compound-limit stmt) scope)]
           [offset (compile-bound (compound-offset stmt) scope)]
           [ops (map car (compound-rest stmt))])
      (values
       cols0
       (lambda ()
         (let* ([rows (let loop ([acc (run0)] [ops ops] [runs runs])
                        (if (null? ops)
                            acc
                            (loop (combine (car ops) acc ((car runs)) colls) (cdr ops) (cdr runs))))]
                [produced (map (lambda (res) (cons res (map (lambda (t) ((car t) #f res)) terms))) rows)]
                [offset (let ([n (and offset (offset))]) (and n (max n 0)))])
           (map car (take-window (sort-produced terms produced) offset (and limit (limit)))))))))

  ;; The collation of each column of the compound (7.4): that of the first simple-select, left to
  ;; right, whose column has one, else binary. parts: the column vectors of the simple-selects.
  (define (column-collations parts)
    (let ([n (vector-length (car parts))])
      (let loop ([k 0] [acc '()])
        (if (= k n)
            (reverse acc)
            (loop (+ k 1)
                  (cons (let scan ([ps parts])
                          (cond [(null? ps) 'binary]
                                [(column-collation (vector-ref (car ps) k)) => cdr]
                                [else (scan (cdr ps))]))
                        acc))))))

  ;; Rows are equal when each value is equal under the collation of its column (colls).
  (define (row-key row colls) (map value-key-under row colls))

  ;; Keeps the first of each equal row (NULLs equal).
  (define (distinct-rows rows colls)
    (let ([seen (make-hashtable equal-hash equal?)])
      (filter (lambda (r)
                (let ([k (row-key r colls)])
                  (and (not (hashtable-ref seen k #f)) (begin (hashtable-set! seen k #t) #t))))
              rows)))

  (define (key-set rows colls)
    (let ([h (make-hashtable equal-hash equal?)])
      (for-each (lambda (r) (hashtable-set! h (row-key r colls) #t)) rows)
      h))

  (define (combine op left right colls)
    (case op
      [(union-all) (append left right)]
      [(union) (distinct-rows (append left right) colls)]
      [(intersect) (let ([in-right (key-set right colls)])
                     (distinct-rows (filter (lambda (r) (hashtable-ref in-right (row-key r colls) #f)) left)
                                    colls))]
      [else (let ([in-right (key-set right colls)])
              (distinct-rows (filter (lambda (r) (not (hashtable-ref in-right (row-key r colls) #f))) left)
                             colls))])))
