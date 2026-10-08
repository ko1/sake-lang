;;; (engine errors) -- the one kind of error the engine reports to the user.
;;;
;;; Any stage of processing (lexing, parsing, compiling, executing) calls
;;; raise-sql-error; (engine exec) catches it and prints "Error: <message>".
(library (engine errors)
  (export raise-sql-error sql-error? sql-error-message)
  (import (rnrs))

  (define-record-type sql-error (fields message))

  (define (raise-sql-error message)
    (raise (make-sql-error message))))
