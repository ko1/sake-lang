;;; Scopes and name resolution (4.2). A scope describes what the names of one query can refer to:
;;; its sources (laid side by side in the joined row), result column aliases, whether aggregate
;;; calls are allowed, and the enclosing query (if this is a subquery).
(library (engine scope)
  (export make-source source-name source-columns source-offset source-hidden source-width
          make-link link? link-scope link-box link-used? link-mark-used!
          make-scope make-aggregate-scope make-misuse-scope scope-db scope-sources scope-aliases
          scope-aggregates scope-outer scope-width scope-with-aliases scope-for-rows
          make-misuse misuse? misuse-direct misuse-via-alias
          lookup-name resolve-name)
  (import (rnrs) (only (chezscheme) box) (engine errors) (engine ast) (engine catalog))

  ;; name: lowercase name of the source or #f; columns: vector of column; offset: index of its first
  ;; column in the joined row; hidden: lowercase names of USING columns merged into a source on the
  ;; left (not reachable unqualified, and left out of `*`).
  (define-record-type source (fields name columns offset hidden))

  (define (source-width s) (vector-length (source-columns s)))

  ;; The link from a subquery to the query enclosing it. box holds the enclosing query's current
  ;; row while the subquery runs; used? tells whether the subquery refers to it (is correlated).
  (define-record-type link
    (fields scope (immutable box) (mutable used?))
    (protocol (lambda (new) (lambda (scope) (new scope (box #f) #f)))))

  (define (link-mark-used! l) (link-used?-set! l #t))

  ;; aggregates: a collector (aggregate calls are allowed and gathered) or a misuse (they are
  ;; errors); the scope does not look inside either.
  (define-record-type (scope make-scope* scope?) (fields db sources aliases aggregates outer))

  ;; direct / via-alias: procedures from an aggregate's name to the error message.
  (define-record-type misuse (fields direct via-alias))

  (define where-misuse
    (make-misuse (lambda (n) (string-append "misuse of aggregate function " n "()"))
                 (lambda (n) (string-append "misuse of aggregate: " n "()"))))

  ;; outer: #f or the link to the enclosing query. Aggregate calls are the error of WHERE (1.7, 3.3).
  (define (make-scope db sources outer) (make-scope* db sources '() where-misuse outer))

  (define (scope-with-aliases sc aliases)
    (make-scope* (scope-db sc) (scope-sources sc) aliases (scope-aggregates sc) (scope-outer sc)))
  (define (scope-with-aggregates sc aggregates)
    (make-scope* (scope-db sc) (scope-sources sc) (scope-aliases sc) aggregates (scope-outer sc)))

  (define (make-aggregate-scope base aliases collector)
    (scope-with-aliases (scope-with-aggregates base collector) aliases))
  (define (make-misuse-scope base aliases direct via-alias)
    (scope-with-aliases (scope-with-aggregates base (make-misuse direct via-alias)) aliases))

  ;; The scope for the arguments of an aggregate call: source columns only.
  (define (scope-for-rows sc)
    (make-scope* (scope-db sc) (scope-sources sc) '() where-misuse (scope-outer sc)))

  ;; Number of columns in the joined row.
  (define (scope-width sc)
    (fold-left (lambda (n s) (+ n (source-width s))) 0 (scope-sources sc)))

  ;; ---- lookup ----

  (define (column-index cols lower)
    (let loop ([i 0])
      (cond [(= i (vector-length cols)) #f]
            [(string=? (column-lower (vector-ref cols i)) lower) i]
            [else (loop (+ i 1))])))

  (define (shown-name q nm)
    (if q (string-append (name-text q) "." (name-text nm)) (name-text nm)))

  ;; What the (optionally qualified) name q.nm stands for, searching this query then the enclosing
  ;; ones; #f if nothing. The answer is one of
  ;;   (slot index column)   a column of the joined row of the query that found it
  ;;   (alias expression)    a result column alias of that query
  ;;   (outer link answer)   something found in the enclosing query link-scope, as answer
  (define (lookup-name sc q nm)
    (or (lookup-here sc q nm)
        (let ([link (scope-outer sc)])
          (and link
               (let ([found (lookup-name (link-scope link) q nm)])
                 (and found (list 'outer link found)))))))

  (define (lookup-here sc q nm)
    (let ([lower (name-lower nm)])
      (if q
          (let ([src (find-source sc (name-lower q))])
            (and src
                 (let ([i (column-index (source-columns src) lower)])
                   (unless i (raise-no-such-column q nm))
                   (list 'slot (+ (source-offset src) i) (vector-ref (source-columns src) i)))))
          (let ([hits (column-hits sc lower)])
            (cond [(null? hits)
                   (let ([a (assoc lower (scope-aliases sc))]) (and a (list 'alias (cdr a))))]
                  [(null? (cdr hits)) (car hits)]
                  [else (raise-sql-error (string-append "ambiguous column name: " (name-text nm)))])))))

  (define (find-source sc lower)
    (let loop ([ss (scope-sources sc)])
      (cond [(null? ss) #f]
            [(equal? (source-name (car ss)) lower) (car ss)]
            [else (loop (cdr ss))])))

  ;; The (slot ...) answers for every reachable column of this name.
  (define (column-hits sc lower)
    (apply append
           (map (lambda (s)
                  (let ([i (and (not (member lower (source-hidden s)))
                                (column-index (source-columns s) lower))])
                    (if i
                        (list (list 'slot (+ (source-offset s) i) (vector-ref (source-columns s) i)))
                        '())))
                (scope-sources sc))))

  (define (raise-no-such-column q nm)
    (raise-sql-error (string-append "no such column: " (shown-name q nm))))

  ;; Like lookup-name, but a name that is nowhere is the error `no such column`.
  (define (resolve-name sc q nm)
    (or (lookup-name sc q nm) (raise-no-such-column q nm))))
