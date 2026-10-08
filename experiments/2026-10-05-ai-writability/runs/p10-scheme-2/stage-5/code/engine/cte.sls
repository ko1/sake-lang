;;; (engine cte) -- WITH clauses (spec 5.2).
;;;
;;; plan-ctes turns a WITH clause into a database view in which the ctes are visible.  A cte
;;; is planned afresh at each use, in the ctes before it.  A recursive cte is run with a queue.
(library (engine cte)
  (export plan-ctes)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine catalog) (engine plan)
          (engine grouping) (engine compound))

  ;; Does a simple select's FROM name `lname` as a table (not inside a subquery)?
  (define (from-mentions? stmt lname)
    (let ([from (select-stmt-from stmt)])
      (and from
           (exists (lambda (item)
                     (and (table-ref? item) (string=? (ascii-downcase (table-ref-name item)) lname)))
                   (cons (from-clause-first from)
                         (map join-clause-item (from-clause-joins from)))))))

  ;; A recursive cte's select: initial UNION [ALL] recursive, the recursive part naming the cte.
  (define (recursive-select? select lname)
    (and (compound-stmt? select)
         (= (length (compound-stmt-rest select)) 1)
         (memq (car (car (compound-stmt-rest select))) '(union union-all))
         (from-mentions? (cdr (car (compound-stmt-rest select))) lname)))

  ;; The plan of a recursive cte.  `env` sees the ctes before it; the recursive part sees the
  ;; cte too, as the one row being expanded.
  (define (plan-recursive env cte plan-query)
    (let* ([select (cte-select cte)]
           [op (car (car (compound-stmt-rest select)))]
           [initial (plan-query env (compound-stmt-first select) #f)]
           [current (vector '())]
           [self (make-cte-entry (cte-name cte) (cte-columns cte)
                                 (lambda ()
                                   (make-plan (plan-names initial) (plan-affinities initial) #f
                                              (lambda () (vector-ref current 0)))))]
           [step (plan-query (database-with-ctes env (list self))
                             (cdr (car (compound-stmt-rest select))) #f)])
      (check-width! op (length (plan-names initial)) step)
      (make-compound-plan
       env select (list initial step)
       (lambda (stop-after)
         (let ([seen (make-row-set)] [distinct? (eq? op 'union)])
           (define (admit? row) (or (not distinct?) (row-set-add! seen row)))
           (let loop ([front (filter admit? ((plan-run initial)))] [back '()] [done '()] [count 0])
             (cond
               [(and stop-after (>= count stop-after)) (reverse done)]
               [(pair? front)
                (vector-set! current 0 (list (car front)))
                (loop (cdr front)
                      (append (reverse (filter admit? ((plan-run step)))) back)
                      (cons (car front) done) (+ count 1))]
               [(pair? back) (loop (reverse back) '() done count)]
               [else (reverse done)])))))))

  ;; The database as the select under `with` sees it.  plan-query: db, query, outer -> plan.
  (define (plan-ctes db with plan-query)
    (let loop ([ctes (with-clause-ctes with)] [env db] [seen '()])
      (if (null? ctes)
          env
          (let* ([cte (car ctes)]
                 [lname (ascii-downcase (cte-name cte))]
                 [definition-env env])
            (when (member lname seen)
              (raise-sql-error (string-append "duplicate WITH table name: " (cte-name cte))))
            (loop (cdr ctes)
                  (database-with-ctes
                   env
                   (list (make-cte-entry
                          (cte-name cte) (cte-columns cte)
                          (if (and (with-clause-recursive with) (recursive-select? (cte-select cte) lname))
                              (lambda () (plan-recursive definition-env cte plan-query))
                              (lambda () (plan-query definition-env (cte-select cte) #f))))))
                  (cons lname seen)))))))
