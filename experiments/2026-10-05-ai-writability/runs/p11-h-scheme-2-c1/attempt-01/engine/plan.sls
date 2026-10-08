;;; (engine plan) -- what planning a SELECT leaves for its user (the executor, a subquery
;;; expression, a FROM item).
(library (engine plan)
  (export make-plan plan-names plan-affinities plan-collations plan-correlated? plan-run)
  (import (rnrs))

  ;; names: result column names (string or #f), affinities: integer/real/text/#f, collations: for
  ;; each result column #f (its expression has none) or (kind . collation) with kind explicit or
  ;; implicit (7.3), each a list;
  ;; correlated?: does it read columns of an enclosing query; run: thunk -> list of result rows.
  (define-record-type plan (fields names affinities collations correlated? run)))
