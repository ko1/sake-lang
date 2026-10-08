;;; (engine sources) -- the named column groups a query's FROM provides (spec 4.1, 4.2).
;;;
;;; The rows of a FROM are the concatenation of the rows of its sources, so a column is
;;; addressed by an absolute index = its source's offset + its position in the source.
(library (engine sources)
  (export source-name source-columns source-offset source-hidden
          sources-add sources-width sources-named sources-ref
          source-column-index source-rowid-index sources-column-matches
          sources-star-columns source-all-columns)
  (import (rnrs) (engine values) (engine catalog))

  ;; name: lower-cased name or #f (an unnamed subquery); columns: vector of catalog columns
  ;; (type = affinity or #f); hidden: lower-cased USING columns whose copy `*` omits.
  (define-record-type source (fields name columns offset hidden))

  (define (sources-width sources)
    (if (null? sources)
        0
        (let ([s (car (reverse sources))]) (+ (source-offset s) (vector-length (source-columns s))))))

  ;; `sources` with one more at the end; name is as written (or #f).
  (define (sources-add sources name columns hidden)
    (append sources (list (make-source (and name (ascii-downcase name)) columns
                                       (sources-width sources) hidden))))

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

  ;; Position in the source of its hidden rowid column (a table source only), or #f.
  (define (source-rowid-index source)
    (let* ([cols (source-columns source)] [n (vector-length cols)])
      (and (> n 0) (rowid-column? (vector-ref cols (- n 1))) (- n 1))))

  ;; The column at an absolute index.
  (define (sources-ref sources index)
    (let ([s (find (lambda (s) (< index (+ (source-offset s) (vector-length (source-columns s))))) sources)])
      (vector-ref (source-columns s) (- index (source-offset s)))))

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

  ;; (absolute-index . column) for every real column of one source (never the rowid).
  (define (source-all-columns source)
    (let ([cols (source-columns source)])
      (map (lambda (i) (cons (+ (source-offset source) i) (vector-ref cols i)))
           (filter (lambda (i) (not (rowid-column? (vector-ref cols i))))
                   (enumerate (vector-length cols))))))

  ;; Those `*` expands to: every source's columns but the hidden USING copies.
  (define (sources-star-columns sources)
    (apply append
           (map (lambda (s)
                  (filter (lambda (entry) (not (member (column-lname (cdr entry)) (source-hidden s))))
                          (source-all-columns s)))
                sources)))

  (define (enumerate n) (let loop ([i (- n 1)] [acc '()]) (if (< i 0) acc (loop (- i 1) (cons i acc))))))
