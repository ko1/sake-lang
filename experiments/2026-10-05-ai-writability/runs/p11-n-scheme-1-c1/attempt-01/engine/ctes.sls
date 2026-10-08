;;; Named queries used as sources: WITH ctes (5.2). A cte is prepared once per statement into an
;;; entry (its columns and a thunk giving its rows as lists of values); the entries visible to the
;;; select being prepared are in the parameter current-ctes, innermost first.
(library (engine ctes)
  (export current-ctes find-cte cte-entry-columns cte-entry-run rename-columns call-with-ctes)
  (import (rnrs) (only (chezscheme) make-parameter parameterize) (engine errors) (engine ast)
          (engine catalog) (engine value))

  ;; Alist from lowercase name to cte-entry.
  (define current-ctes (make-parameter '()))

  (define-record-type cte-entry (fields columns run))

  (define (find-cte lower)
    (let ([a (assoc lower (current-ctes))]) (and a (cdr a))))

  ;; The columns cols of a view or cte called who, named by names (a list of names, or #f for
  ;; their own names).
  (define (rename-columns cols names who)
    (cond
      [(not names) cols]
      [(not (= (length names) (vector-length cols)))
       (raise-sql-error (string-append "table " who " has " (number->string (vector-length cols))
                                       " values for " (number->string (length names)) " columns"))]
      [else
       (list->vector
        (map (lambda (nm c)
               (let ([text (if (name? nm) (name-text nm) nm)])
                 (make-column text (string-downcase text) (column-type c) #f #f (column-collation c))))
             names (vector->list cols)))]))

  ;; Prepares the ctes of with-stmt w, each seeing those before it, and calls thunk with them all
  ;; visible, returning what it returns. prepare is the select planner (see (engine expr)).
  (define (call-with-ctes db w prepare thunk)
    (let ([ctes (with-stmt-ctes w)])
      (let check ([l ctes] [seen '()])
        (unless (null? l)
          (let ([lower (name-lower (cte-name (car l)))])
            (when (member lower seen)
              (raise-sql-error (string-append "duplicate WITH table name: " (name-text (cte-name (car l))))))
            (check (cdr l) (cons lower seen)))))
      (let loop ([l ctes])
        (if (null? l)
            (thunk)
            (let ([entry (prepare-cte db (car l) (with-stmt-recursive? w) prepare)])
              (parameterize ([current-ctes (cons (cons (name-lower (cte-name (car l))) entry)
                                                 (current-ctes))])
                (loop (cdr l))))))))

  (define (cached thunk)
    (let ([cache #f])
      (lambda () (or cache (begin (set! cache (thunk)) cache)))))

  (define (prepare-cte db c recursive? prepare)
    (let ([query (cte-query c)] [lower (name-lower (cte-name c))] [who (name-text (cte-name c))])
      (if (and recursive? (recursive-shape? query lower))
          (prepare-recursive db c query prepare)
          (let-values ([(cols run) (prepare db query #f)])
            (make-cte-entry (rename-columns cols (cte-columns c) who) (cached run))))))

  ;; initial UNION [ALL] recursive, where recursive's FROM mentions the cte.
  (define (recursive-shape? query lower)
    (and (compound? query)
         (= (length (compound-rest query)) 1)
         (memq (car (car (compound-rest query))) '(union union-all))
         (null? (compound-order query))
         (from-mentions? (select-stmt-from (cdr (car (compound-rest query)))) lower)))

  ;; Whether the from-item (not looking into subqueries) names the table lower.
  (define (from-mentions? item lower)
    (cond [(from-table? item) (string=? (name-lower (from-table-name item)) lower)]
          [(from-join? item) (or (from-mentions? (from-join-left item) lower)
                                 (from-mentions? (from-join-right item) lower))]
          [else #f]))

  ;; The queue algorithm of 5.2: the recursive select runs once per row taken from the queue, with
  ;; the cte standing for that row.
  (define (prepare-recursive db c query prepare)
    (let* ([who (name-text (cte-name c))]
           [lower (name-lower (cte-name c))]
           [all? (eq? (car (car (compound-rest query))) 'union-all)]
           [recursive (cdr (car (compound-rest query)))])
      (let-values ([(icols irun) (prepare db (compound-first query) #f)])
        (let* ([cols (rename-columns icols (cte-columns c) who)]
               ;; UNION compares rows under the collations of the initial select's columns (7.4)
               [colls (map (lambda (col) (if (column-collation col) (cdr (column-collation col)) 'binary))
                           (vector->list icols))]
               [current '()]
               [self (make-cte-entry cols (lambda () current))])
          (parameterize ([current-ctes (cons (cons lower self) (current-ctes))])
            (let-values ([(rcols rrun) (prepare db recursive #f)])
              (unless (= (vector-length rcols) (vector-length icols))
                (raise-sql-error
                 (string-append "SELECTs to the left and right of "
                                (if all? "UNION ALL" "UNION")
                                " do not have the same number of result columns")))
              (make-cte-entry
               cols
               (cached
                (lambda ()
                  (let ([seen (make-hashtable equal-hash equal?)]
                        [front '()] [back '()] [result '()])
                    (define (enqueue! row)
                      (let ([key (map value-key-under row colls)])
                        (unless (and (not all?) (hashtable-ref seen key #f))
                          (hashtable-set! seen key #t)
                          (set! back (cons row back)))))
                    (for-each enqueue! (irun))
                    (let loop ()
                      (when (and (null? front) (pair? back))
                        (set! front (reverse back))
                        (set! back '()))
                      (when (pair? front)
                        (let ([row (car front)])
                          (set! front (cdr front))
                          (set! result (cons row result))
                          (set! current (list row))
                          (for-each enqueue! (rrun))
                          (loop))))
                    (reverse result))))))))))))
