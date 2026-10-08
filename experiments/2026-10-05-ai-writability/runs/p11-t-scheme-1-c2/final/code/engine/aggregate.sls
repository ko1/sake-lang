;;; Aggregate functions (3.2): which calls are aggregates, how a group of rows is folded into a value,
;;; and the collector that gathers the distinct aggregate calls of one query.
(library (engine aggregate)
  (export aggregate-kind aggregate-name? find-aggregate
          make-collector collector? collector-register! collector-specs
          make-agg-spec agg-spec-kind agg-spec-args agg-spec-distinct?
          compute-aggregate extreme-kind?)
  (import (rnrs) (engine errors) (engine ast) (engine value) (engine numeric))

  (define aggregate-names '("count" "sum" "total" "avg" "min" "max" "group_concat"))
  (define (aggregate-name? lower) (and (member lower aggregate-names) #t))

  ;; The kind (count-star count sum total avg min max group-concat) of the aggregate call with this
  ;; lowercase name and argument count, or #f when it is not one (`max(a, b)` is the scalar).
  (define (aggregate-kind lower argc star?)
    (cond [(string=? lower "count") (cond [(or star? (= argc 0)) 'count-star] [(= argc 1) 'count] [else #f])]
          [star? #f]
          [(member lower '("sum" "total" "avg" "min" "max"))
           (and (= argc 1) (string->symbol lower))]
          [(string=? lower "group_concat") (and (<= 1 argc 2) 'group-concat)]
          [else #f]))

  (define (extreme-kind? kind) (and (memq kind '(min max)) #t))

;; The name (as written) of the first aggregate call inside the expression ast, or #f. A call with
  ;; OVER is a window call (6.3), not an aggregate, though its arguments may hold aggregates.
  (define (find-aggregate ast)
    (find-call (lambda (c)
                 (and (not (list-ref c 6))
                      (aggregate-kind (name-lower (cadr c)) (length (caddr c)) (list-ref c 5))
                      #t))
               ast))

    ;; ---- the aggregate calls of one query ----

  ;; args: procedures from a source row to a value. order: list of (procedure descending? nulls-first?).
  (define-record-type agg-spec (fields kind distinct? args order))

  ;; entries: list of (key . spec), newest first. Identical calls (same key) share one spec.
  (define-record-type collector (fields (mutable entries))
    (protocol (lambda (new) (lambda () (new '())))))

  ;; The index of the spec for this call key, adding spec if the key is new.
  (define (collector-register! c key spec)
    (let ([found (let loop ([es (collector-entries c)] [i (- (length (collector-entries c)) 1)])
                   (cond [(null? es) #f]
                         [(equal? (caar es) key) i]
                         [else (loop (cdr es) (- i 1))]))])
      (or found
          (begin (collector-entries-set! c (cons (cons key spec) (collector-entries c)))
                 (- (length (collector-entries c)) 1)))))

  (define (collector-specs c) (map cdr (reverse (collector-entries c))))

  ;; ---- computing ----

  ;; The value of the aggregate over rows (a list of source-row vectors, in row order).
  (define (compute-aggregate spec rows)
    (let ([kind (agg-spec-kind spec)])
      (if (eq? kind 'count-star)
          (length rows)
          (let* ([rows (if (null? (agg-spec-order spec)) rows (sort-rows (agg-spec-order spec) rows))]
                 [firsts (map (lambda (r) ((car (agg-spec-args spec)) r)) rows)]
                 [keep (filter-not-null rows firsts)]
                 [keep (if (agg-spec-distinct? spec) (distinct-by-value keep) keep)]
                 [vals (map car keep)])
            (case kind
              [(count) (length vals)]
              [(sum total avg) (fold-sum kind vals)]
              [(min) (extreme vals (lambda (c) (< c 0)))]
              [(max) (extreme vals (lambda (c) (> c 0)))]
              [else (group-concat spec keep)])))))

  ;; Pairs (value . row) for the non-NULL values.
  (define (filter-not-null rows vals)
    (let loop ([rows rows] [vals vals] [acc '()])
      (cond [(null? rows) (reverse acc)]
            [(sql-null? (car vals)) (loop (cdr rows) (cdr vals) acc)]
            [else (loop (cdr rows) (cdr vals) (cons (cons (car vals) (car rows)) acc))])))

  (define (distinct-by-value pairs)
    (let ([seen (make-hashtable equal-hash equal?)])
      (let loop ([ps pairs] [acc '()])
        (cond [(null? ps) (reverse acc)]
              [(hashtable-ref seen (value-key (caar ps)) #f) (loop (cdr ps) acc)]
              [else (hashtable-set! seen (value-key (caar ps)) #t) (loop (cdr ps) (cons (car ps) acc))]))))

  (define (sort-rows terms rows)
    (list-sort
     (lambda (a b)
       (let loop ([ts terms])
         (and (pair? ts)
              (let* ([t (car ts)]
                     [c (compare-for-sort ((car t) a) ((car t) b) (cadr t) (caddr t))])
                (cond [(< c 0) #t] [(> c 0) #f] [else (loop (cdr ts))])))))
     rows))

  (define (extreme vals better?)
    (if (null? vals)
        sql-null
        (fold-left (lambda (best v) (if (better? (compare-values v best)) v best))
                   (car vals) (cdr vals))))

  ;; A value as (number . integer?) for sum (3.2): numeric-literal TEXT counts as its number,
  ;; other TEXT is a non-INTEGER read by numeric prefix; a BLOB is always non-INTEGER (7.8).
  (define (summand v)
    (cond [(sql-blob? v) (cons (inexact (numeric-prefix (text-form v))) #f)]
          [(string? v) (let ([n (parse-numeric-text v)])
                         (if n (cons n (sql-integer? n)) (cons (inexact (numeric-prefix v)) #f)))]
          [else (cons v (sql-integer? v))]))

  (define (fold-sum kind vals)
    (let* ([terms (map summand vals)]
           [all-integer? (for-all cdr terms)])
      (cond
        [(null? terms) (case kind [(total) 0.0] [else sql-null])]
        [all-integer?
         (let ([sum (apply + (map car terms))])
           (when (or (> sum int64-max) (< sum int64-min)) (raise-sql-error "integer overflow"))
           (case kind
             [(sum) sum]
             [(total) (inexact sum)]
             [else (/ (inexact sum) (length terms))]))]
        [else
         (let ([real-sum (compensated-sum (map car terms))])
           (case kind
             [(avg) (/ real-sum (length terms))]
             [else real-sum]))])))

  ;; The REAL sum of 3.2: the leading INTEGERs exactly, then compensated addition.
  (define (compensated-sum nums)
    (let split ([nums nums] [prefix 0])
      (if (and (pair? nums) (exact? (car nums)))
          (split (cdr nums) (+ prefix (car nums)))
          (let loop ([vs nums] [s (inexact prefix)] [c 0.0])
            (if (null? vs)
                (+ s c)
                (let* ([v (inexact (car vs))] [t (+ s v)])
                  (loop (cdr vs) t
                        (if (> (abs s) (abs v)) (+ c (+ (- s t) v)) (+ c (+ (- v t) s))))))))))

  ;; group_concat: keep is the list of (value . row); the separator is evaluated per row.
  (define (group-concat spec keep)
    (if (null? keep)
        sql-null
        (let ([sep (if (null? (cdr (agg-spec-args spec)))
                       (lambda (row) ",")
                       (lambda (row) (let ([s ((cadr (agg-spec-args spec)) row)])
                                       (if (sql-null? s) "" (text-form s)))))])
          (let loop ([ps (cdr keep)] [acc (list (text-form (caar keep)))])
            (if (null? ps)
                (apply string-append (reverse acc))
                (loop (cdr ps)
                      (cons (text-form (caar ps)) (cons (sep (cdar ps)) acc))))))))
)
