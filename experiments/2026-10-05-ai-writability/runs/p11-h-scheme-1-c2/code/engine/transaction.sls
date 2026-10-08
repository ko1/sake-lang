;;; BEGIN, COMMIT / END, ROLLBACK (5.5). The snapshot itself lives in (engine catalog).
(library (engine transaction)
  (export execute-transaction)
  (import (rnrs) (engine errors) (engine ast) (engine catalog))

  (define (execute-transaction db stmt)
    (case (transaction-kind stmt)
      [(begin)
       (when (database-in-transaction? db)
         (raise-sql-error "cannot start a transaction within a transaction"))
       (database-begin! db)]
      [(commit)
       (unless (database-in-transaction? db)
         (raise-sql-error "cannot commit - no transaction is active"))
       (database-commit! db)]
      [else
       (unless (database-in-transaction? db)
         (raise-sql-error "cannot rollback - no transaction is active"))
       (database-rollback! db)])))
