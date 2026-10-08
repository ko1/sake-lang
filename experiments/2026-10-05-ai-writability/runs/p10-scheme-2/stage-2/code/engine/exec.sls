;;; (engine exec) -- dispatching statements to their executors, and whole scripts.
(library (engine exec)
  (export run-script)
  (import (rnrs) (engine errors) (engine values) (engine lexer) (engine parser)
          (engine ast) (engine catalog) (engine ddl) (engine dml) (engine select))

  ;;; ---- dispatch and scripts ---------------------------------------------------------

  (define (print-rows rows out)
    (for-each (lambda (row)
                (let loop ([vals (vector->list row)] [first? #t])
                  (unless (null? vals)
                    (unless first? (put-char out #\|))
                    (put-string out (value->display (car vals)))
                    (loop (cdr vals) #f)))
                (put-char out #\newline))
              rows))

  (define (execute db stmt out)
    (cond [(select-stmt? stmt) (print-rows (run-select db stmt) out)]
          [(insert-stmt? stmt) (exec-insert db stmt)]
          [(update-stmt? stmt) (exec-update db stmt)]
          [(delete-stmt? stmt) (exec-delete db stmt)]
          [(create-table-stmt? stmt) (exec-create-table db stmt)]
          [(drop-table-stmt? stmt) (exec-drop-table db stmt)]))

  (define (report-error out message)
    (put-string out "Error: ") (put-string out message) (put-char out #\newline))

  (define (run-statement db text out)
    (guard (e [(sql-error? e) (report-error out (sql-error-message e))]
              [(error? e) (report-error out (condition-message-text e))])
      (let ([stmt (parse-statement (tokenize text))])
        (when stmt (execute db stmt out)))))

  ;; Internal failures (bugs) still keep the script going.
  (define (condition-message-text e)
    (if (message-condition? e) (condition-message e) "internal error"))

  ;; Run every statement of `text` in a fresh database, writing to the textual port `out`.
  (define (run-script text out)
    (let ([db (make-database)])
      (for-each (lambda (statement-text) (run-statement db statement-text out))
                (split-statements text)))))
