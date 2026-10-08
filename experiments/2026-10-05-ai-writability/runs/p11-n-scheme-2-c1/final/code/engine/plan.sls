;;; (engine plan) -- what planning a SELECT leaves for its user (the executor, a subquery
;;; expression, a FROM item).
(library (engine plan)
  (export make-plan plan-names plan-affinities plan-collations plan-collation-symbols plan-correlated? plan-run)
  (import (rnrs))

  ;; names: result column names (string or #f), affinities: integer/real/text/#f, each a list;
  ;; collations: each a result column's collation (7.3) -- #f (none), (explicit . symbol) or
  ;; (implicit . symbol).
  ;; correlated?: does it read columns of an enclosing query; run: thunk -> list of result rows.
  (define-record-type plan (fields names affinities collations correlated? run))

  ;; The collation symbol of each result column; binary where it has none.
  (define (plan-collation-symbols plan)
    (map (lambda (c) (if c (cdr c) 'binary)) (plan-collations plan))))
