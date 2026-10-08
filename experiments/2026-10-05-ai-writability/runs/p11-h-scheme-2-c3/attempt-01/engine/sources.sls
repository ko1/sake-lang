;;; (engine sources) -- the named column groups a query's FROM provides (spec 4.1, 4.2).
;;;
;;; The rows of a FROM are the concatenation of the rows of its sources, so a column is
;;; addressed by an absolute index = its source's offset + its position in the source.
(library (engine sources)
  (export source-name source-columns source-offset source-hidden source-rowid?
          rowid-name? source-rowid-index sources-rowid-match
          sources-add sources-width sources-named sources-ref
          source-column-index sources-column-matches
          sources-star-columns source-all-columns)
  (import (rnrs) (engine values) (engine catalog))

  ;; name: lower-cased name or #f (an unnamed subquery); columns: vector of catalog columns
  ;; (type = affinity or #f); hidden: lower-cased USING columns whose copy `*` omits.
  ;; rowid?: the source is a table, whose rows carry its rowid in one extra slot after the
  ;; columns (spec 7.1); the slot is addressed by absolute index but is not among `columns`.
  (define-record-type source (fields name columns offset hidden rowid?))

  ;; Number of row slots the source takes: its columns, plus the rowid slot of a table.
  (define (source-width s)
    (+ (vector-length (source-columns s)) (if (source-rowid? s) 1 0)))

  (define (sources-width sources)
    (if (null? sources)
        0
        (let ([s (car (reverse sources))]) (+ (source-offset s) (source-width s)))))

  ;; `sources` with one more at the end; name is as written (or #f).
  (define (sources-add sources name columns hidden rowid?)
    (append sources (list (make-source (and name (ascii-downcase name)) columns
                                       (sources-width sources) hidden rowid?))))

  ;; The names of a table's rowid (spec 7.1), lower-cased.
  (define (rowid-name? lname)
    (and (member lname '("rowid" "_rowid_" "oid")) #t))

  ;; Absolute index of the rowid slot of a source that is a table.
  (define (source-rowid-index s) (+ (source-offset s) (vector-length (source-columns s))))

  ;; What an unqualified name that is no real column of any source means as a rowid name:
  ;; #f (not a rowid), the absolute index of the rowid slot, or the symbol `ambiguous` (several
  ;; sources, at least one a table).
  (define (sources-rowid-match sources lname)
    (cond [(not (rowid-name? lname)) #f]
          [(null? sources) #f]
          [(null? (cdr sources)) (and (source-rowid? (car sources)) (source-rowid-index (car sources)))]
          [(exists source-rowid? sources) 'ambiguous]
          [else #f]))

  ;; The pseudo-column the rowid slot stands for: an INTEGER named rowid.
  (define rowid-column (make-column "rowid" "rowid" 'integer #f sql-null))

  ;; The first source with this lower-cased name, or #f.
  (define (sources-named sources lname)
    (find (lambda (s) (equal? (source-name s) lname)) sources))

  ;; Position in the source of the column with this lower-cased name, or #f.
  (define (source-column-index source lname)
    (let ([cols (source-columns source)])
      (let loop ([i 0])
        (cond [(= i (vector-length cols)) #f]
              [(string=? (column-lname (vector-ref cols i)) lname) i]
              [else (loop (+ i 1))]))))

  ;; The column at an absolute index (a table's rowid slot gives the INTEGER rowid column).
  (define (sources-ref sources index)
    (let ([s (find (lambda (s) (< index (+ (source-offset s) (source-width s)))) sources)])
      (if (< (- index (source-offset s)) (vector-length (source-columns s)))
          (vector-ref (source-columns s) (- index (source-offset s)))
          rowid-column)))

  ;; Absolute indexes of the columns an unqualified name can mean.  A USING column is one
  ;; column: the first source's copy.
  (define (sources-column-matches sources lname)
    (let ([all (filter values
                       (map (lambda (s)
                              (let ([i (source-column-index s lname)])
                                (and i (+ (source-offset s) i))))
                            sources))])
      (if (and (pair? all) (exists (lambda (s) (member lname (source-hidden s))) sources))
          (list (car all))
          all)))

  ;; (absolute-index . column) for every column of one source.
  (define (source-all-columns source)
    (let ([cols (source-columns source)])
      (map (lambda (i) (cons (+ (source-offset source) i) (vector-ref cols i)))
           (enumerate (vector-length cols)))))

  ;; Those `*` expands to: every source's columns but the hidden USING copies.
  (define (sources-star-columns sources)
    (apply append
           (map (lambda (s)
                  (filter (lambda (entry) (not (member (column-lname (cdr entry)) (source-hidden s))))
                          (source-all-columns s)))
                sources)))

  (define (enumerate n) (let loop ([i (- n 1)] [acc '()]) (if (< i 0) acc (loop (- i 1) (cons i acc))))))
