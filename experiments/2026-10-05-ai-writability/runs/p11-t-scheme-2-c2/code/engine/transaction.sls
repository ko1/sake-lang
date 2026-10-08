;;; (engine transaction) -- BEGIN, COMMIT / END and ROLLBACK (spec 5.5).
;;;
;;; BEGIN takes a snapshot of the database; ROLLBACK puts it back.  A failed statement has no
;;; effect of its own, so nothing else is needed to keep the transaction open.
(library (engine transaction)
  (export exec-transaction)
  (import (rnrs) (engine errors) (engine ast) (engine catalog))

  (define (exec-transaction db stmt)
    (let ([snapshot (database-transaction db)])
      (case (transaction-stmt-action stmt)
        [(begin)
         (when snapshot (raise-sql-error "cannot start a transaction within a transaction"))
         (database-transaction-set! db (database-snapshot db))]
        [(commit)
         (unless snapshot (raise-sql-error "cannot commit - no transaction is active"))
         (database-transaction-set! db #f)]
        [else
         (unless snapshot (raise-sql-error "cannot rollback - no transaction is active"))
         (database-restore! db snapshot)
         (database-transaction-set! db #f)]))))
