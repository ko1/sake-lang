;;; SQL errors: a statement that fails raises one of these; the script runner prints "Error: <message>".
(library (engine errors)
  (export sql-error? sql-error-message raise-sql-error raise-syntax-error)
  (import (rnrs))

  (define-record-type sql-error (fields message))

  (define (raise-sql-error message) (raise (make-sql-error message)))

  (define (raise-syntax-error) (raise-sql-error "syntax error")))
