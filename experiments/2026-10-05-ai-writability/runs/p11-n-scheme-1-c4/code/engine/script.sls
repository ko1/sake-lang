;;; Running a script: split it into statements, run each, print results and errors (1.1).
(library (engine script)
  (export run-script)
  (import (rnrs) (only (chezscheme) display-condition) (engine errors) (engine lexer)
          (engine parser) (engine ast) (engine catalog) (engine ddl) (engine insert)
          (engine select) (engine update) (engine value) (engine alter) (engine transaction))

  ;; Executes a parsed statement. Returns the lines to print.
  (define (execute db stmt)
    (cond [(with-stmt? stmt)
           (call-with-statement-ctes db stmt (lambda () (execute db (with-stmt-body stmt))))]
          [(query? stmt)
           (map (lambda (row) (join-with "|" (map display-form row))) (execute-select db stmt))]
          [(create-table? stmt) (execute-create-table db stmt) '()]
          [(create-view? stmt) (execute-create-view db stmt) '()]
          [(create-index? stmt) (execute-create-index db stmt) '()]
          [(drop-table? stmt) (execute-drop-table db stmt) '()]
          [(drop-view? stmt) (execute-drop-view db stmt) '()]
          [(drop-index? stmt) (execute-drop-index db stmt) '()]
          [(alter-add-column? stmt) (execute-alter-add-column db stmt) '()]
          [(alter-rename-table? stmt) (execute-alter-rename-table db stmt) '()]
          [(alter-rename-column? stmt) (execute-alter-rename-column db stmt) '()]
          [(transaction? stmt) (execute-transaction db stmt) '()]
          [(insert? stmt) (execute-insert db stmt) '()]
          [(update? stmt) (execute-update db stmt) '()]
          [(delete? stmt) (execute-delete db stmt) '()]
          [else (raise-syntax-error)]))

  (define (join-with sep strs)
    (if (null? strs)
        ""
        (fold-left (lambda (acc s) (string-append acc sep s)) (car strs) (cdr strs))))

  (define (run-statement db text out)
    (guard (e [(sql-error? e)
               (put-string out (string-append "Error: " (sql-error-message e) "\n"))]
              [(condition? e)
               (display-condition e (current-error-port))
               (newline (current-error-port))
               (put-string out "Error: internal error\n")])
      (let ([tokens (tokenize text)])
        (unless (null? tokens)
          (for-each (lambda (line) (put-string out (string-append line "\n")))
                    (execute db (parse-statement tokens)))))))

  (define (run-script text out)
    (let ([db (make-database)])
      (for-each (lambda (stmt) (run-statement db stmt out)) (split-statements text))
      (flush-output-port out))))
