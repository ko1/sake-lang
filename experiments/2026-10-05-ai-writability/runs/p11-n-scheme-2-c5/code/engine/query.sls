;;; (engine query) -- running a query: WITH, a compound select or a simple SELECT (spec 5.1, 5.2).
;;;
;;; plan-select is the entry for every place a select may stand (statement, subquery
;;; expression, FROM item, view, cte, INSERT source).  It resolves every name and returns a
;;; plan; running the plan gives the result rows (vectors of values).
(library (engine query)
  (export plan-select run-select)
  (import (rnrs) (engine ast) (engine plan) (engine expr) (engine select) (engine compound)
          (engine cte))

  ;; outer: the scope the query is a subquery in, or #f.
  (define (plan-select db stmt outer)
    (let ([with (query-with stmt)])
      (plan-body (if with (plan-ctes db with plan-select) db) stmt outer)))

  ;; The query without its WITH, in a db that shows the ctes.
  (define (plan-body db stmt outer)
    (if (compound-stmt? stmt)
        (plan-compound db stmt (lambda (part) (plan-simple-select db part outer plan-select)))
        (plan-simple-select db stmt outer plan-select)))

  (define (run-select db stmt) ((plan-run (plan-select db stmt #f))))

  (install-subquery-planner! plan-select))
