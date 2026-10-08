;;; UPDATE and DELETE (2.2).
(library (engine update)
  (export execute-update execute-delete)
  (import (rnrs) (engine errors) (engine ast) (engine catalog) (engine value) (engine scope) (engine expr)
          (engine constraints))

  (define (find-table db nm)
    (or (database-find-table db (name-lower nm))
        (raise-sql-error (string-append "no such table: " (name-text nm)))))

  ;; The target table is a source named by its table name, which subqueries may refer to (4.2).
  (define (table-scope db table)
    (make-scope db (list (make-source (table-lower table) (table-columns table) 0 '())) #f))

  (define (compile-where db table where)
    (and where (compile-expr where (table-scope db table))))

  (define (matches? where row) (or (not where) (eq? #t (truth (where row)))))

  (define (execute-delete db stmt)
    (let* ([table (find-table db (delete-table stmt))]
           [where (compile-where db table (delete-where stmt))])
      (table-set-rows! table (filter (lambda (row) (not (matches? where row))) (table-rows table)))))

  ;; Assignments as a list of (column-index . procedure); a column named twice keeps the last.
  (define (compile-assignments db table assignments)
    (let ([compiled
           (map (lambda (a)
                  (cons (or (table-find-column table (name-lower (car a)))
                            (raise-sql-error (string-append "no such column: " (name-text (car a)))))
                        (compile-expr (cdr a) (table-scope db table))))
                assignments)])
      (let loop ([l (reverse compiled)] [seen '()] [acc '()])
        (cond [(null? l) acc]
              [(memv (caar l) seen) (loop (cdr l) seen acc)]
              [else (loop (cdr l) (cons (caar l) seen) (cons (car l) acc))]))))

  ;; Rows are updated one at a time, in order; each is checked against the other rows as they
  ;; are at that moment.
  (define (execute-update db stmt)
    (let* ([table (find-table db (update-table stmt))]
           [sets (compile-assignments db table (update-assignments stmt))]
           [where (compile-where db table (update-where stmt))]
           [rows (list->vector (table-rows table))])
      (do ([i 0 (+ i 1)]) ((= i (vector-length rows)))
        (let ([old (vector-ref rows i)])
          (when (matches? where old)
            (let ([raw (vector-copy old)])
              (for-each (lambda (s) (vector-set! raw (car s) ((cdr s) old))) sets)
              (vector-set! rows i (store-row table raw (other-row? rows i)))))))
      (table-set-rows! table (vector->list rows))))

  (define (other-row? rows self)
    (lambda (pred)
      (let loop ([j 0])
        (and (< j (vector-length rows))
             (or (and (not (= j self)) (pred (vector-ref rows j)))
                 (loop (+ j 1)))))))

  (define (vector-copy v)
    (let ([c (make-vector (vector-length v))])
      (do ([i 0 (+ i 1)]) ((= i (vector-length v)) c)
        (vector-set! c i (vector-ref v i))))))
