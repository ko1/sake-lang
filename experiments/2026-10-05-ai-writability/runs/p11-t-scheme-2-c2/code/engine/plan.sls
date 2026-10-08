;;; (engine plan) -- what planning a SELECT leaves for its user (the executor, a subquery
;;; expression, a FROM item).
(library (engine plan)
  (export make-plan plan-names plan-affinities plan-correlated? plan-run)
  (import (rnrs))

  ;; names: result column names (string or #f), affinities: integer/real/text/#f, each a list;
  ;; correlated?: does it read columns of an enclosing query; run: thunk -> list of result rows.
  (define-record-type plan (fields names affinities correlated? run)))
