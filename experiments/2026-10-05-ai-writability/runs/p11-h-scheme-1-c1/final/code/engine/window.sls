;;; Window functions (6): the plans compiled from window calls, the collector gathering the calls of
;;; one query, and their evaluation over the rows a query produces before DISTINCT / ORDER BY / LIMIT.
(library (engine window)
  (export window-function-arity window-function-name? resolve-window check-frame
          make-window-collector window-collector-register! window-collector-base
          window-collector-base-set! window-collector-empty?
          make-wplan add-window-values)
  (import (rnrs) (engine errors) (engine ast) (engine value) (engine arith) (engine aggregate))

  ;; ---- the window-only functions (6.3) ----

  ;; lowercase name -> (min-args . max-args)
  (define function-arities
    '(("row_number" 0 . 0) ("rank" 0 . 0) ("dense_rank" 0 . 0) ("percent_rank" 0 . 0)
      ("cume_dist" 0 . 0) ("ntile" 1 . 1) ("lag" 1 . 3) ("lead" 1 . 3)
      ("first_value" 1 . 1) ("last_value" 1 . 1) ("nth_value" 2 . 2)))

  (define (window-function-name? lower) (and (assoc lower function-arities) #t))
  (define (window-function-arity lower)
    (let ([e (assoc lower function-arities)]) (and e (cdr e))))

  ;; ---- window specs: named windows and frame checks (6.1, 6.2) ----

  ;; The wspec that `over` stands for (a name or a wspec), with its base window merged in: the
  ;; spec's own partition, order and frame, else the base's. defs: list of (name . wspec).
  (define (resolve-window over defs)
    (let resolve ([spec (if (pair? over) over (list 'wspec over '() '() #f))] [seen '()])
      (let ([base (cadr spec)])
        (if (not base)
            spec
            (let ([def (assoc (name-lower base) (map (lambda (d) (cons (name-lower (car d)) (cdr d))) defs))])
              (when (or (not def) (member (name-lower base) seen))
                (raise-sql-error (string-append "no such window: " (name-text base))))
              (let ([b (resolve (cdr def) (cons (name-lower base) seen))])
                (list 'wspec #f
                      (if (null? (caddr spec)) (caddr b) (caddr spec))
                      (if (null? (cadddr spec)) (cadddr b) (cadddr spec))
                      (or (list-ref spec 4) (list-ref b 4)))))))))

  ;; Raises the error for a frame (units start end) that is not allowed (6.2); n-order: the number
  ;; of ORDER BY terms.
  (define (check-frame frame n-order)
    (when frame
      (let* ([units (car frame)] [start (cadr frame)] [end (caddr frame)]
             [kind-of car])
        (define (check-offset b which)
          (when (memq (kind-of b) '(preceding following))
            (let ([n (cadr b)])
              (when (or (< n 0) (and (eq? units 'rows) (not (sql-integer? n))))
                (raise-sql-error
                 (string-append "frame " which " offset must be a non-negative "
                                (if (eq? units 'rows) "integer" "number")))))))
        (check-offset start "starting")
        (check-offset end "ending")
        (when (or (and (eq? (kind-of start) 'current-row) (eq? (kind-of end) 'preceding))
                  (and (eq? (kind-of start) 'following)
                       (memq (kind-of end) '(current-row preceding))))
          (raise-sql-error "unsupported frame specification"))
        (when (and (eq? units 'range)
                   (or (memq (kind-of start) '(preceding following))
                       (memq (kind-of end) '(preceding following)))
                   (not (= n-order 1)))
          (raise-sql-error "RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression")))))

  ;; ---- plans and the collector ----

  ;; function: the symbol named like a window-only function (row_number, lag, ...), or agg for an aggregate over the frame
  ;; (then aggregate holds its agg-spec). args, partition: procedures from an evaluation row to a
  ;; value. partition-colls: their collations (7.4). order: list of (procedure descending?
  ;; nulls-first? collation). frame: (units start end), see (engine ast); default is RANGE
  ;; UNBOUNDED PRECEDING to CURRENT ROW.
  (define-record-type wplan (fields function aggregate args partition partition-colls order frame))

  ;; entries: list of (key . wplan), newest first; base: index in the evaluation row of the first
  ;; window value, set once the query is compiled (the row is the source row, then aggregates).
  (define-record-type window-collector
    (fields (mutable entries) (mutable base))
    (protocol (lambda (new) (lambda () (new '() #f)))))

  (define (window-collector-empty? c) (null? (window-collector-entries c)))

  ;; The index of the plan for this call key, adding plan if the key is new.
  (define (window-collector-register! c key plan)
    (let loop ([es (window-collector-entries c)] [i (- (length (window-collector-entries c)) 1)])
      (cond [(null? es)
             (window-collector-entries-set! c (cons (cons key plan) (window-collector-entries c)))
             (- (length (window-collector-entries c)) 1)]
            [(equal? (caar es) key) i]
            [else (loop (cdr es) (- i 1))])))

  ;; ---- evaluation ----

  ;; rows: the evaluation rows (vectors). Returns them with the window values appended, one per
  ;; plan in registration order.
  (define (add-window-values collector rows)
    (let ([plans (map cdr (reverse (window-collector-entries collector)))])
      (if (null? plans)
          rows
          (let* ([rv (list->vector rows)]
                 [results (map (lambda (plan) (compute-plan plan rv)) plans)])
            (let loop ([i (- (vector-length rv) 1)] [acc '()])
              (if (< i 0)
                  acc
                  (loop (- i 1)
                        (cons (list->vector (append (vector->list (vector-ref rv i))
                                                    (map (lambda (r) (vector-ref r i)) results)))
                              acc))))))))

  ;; The window values of one plan, a vector parallel to rv.
  (define (compute-plan plan rv)
    (let ([out (make-vector (vector-length rv) sql-null)])
      (for-each (lambda (part) (compute-partition plan rv part out))
                (partitions plan rv))
      out))

  ;; Lists of row indices, one list per partition, in order of first appearance.
  (define (partitions plan rv)
    (let ([table (make-hashtable equal-hash equal?)] [order '()])
      (do ([i 0 (+ i 1)]) ((= i (vector-length rv)))
        (let* ([row (vector-ref rv i)]
               [key (map (lambda (f c) (value-key (f row) c)) (wplan-partition plan) (wplan-partition-colls plan))]
               [cell (hashtable-ref table key #f)])
          (if cell
              (vector-set! cell 0 (cons i (vector-ref cell 0)))
              (let ([cell (vector (list i))])
                (hashtable-set! table key cell)
                (set! order (cons cell order))))))
      (map (lambda (cell) (reverse (vector-ref cell 0))) (reverse order))))

  (define (compute-partition plan rv indices out)
    (let* ([terms (wplan-order plan)]
           [keyed (map (lambda (i)
                         (let ([row (vector-ref rv i)])
                           (cons i (map (lambda (t) ((car t) row)) terms))))
                       indices)]
           [sorted (if (null? terms)
                       keyed
                       (list-sort (lambda (a b) (< (compare-keys terms (cdr a) (cdr b)) 0)) keyed))]
           [m (length sorted)]
           [idx (list->vector (map car sorted))]
           [keys (list->vector (map cdr sorted))]
           [rows (list->vector (map (lambda (p) (vector-ref rv (car p))) sorted))]
           [peer-start (make-vector m 0)] [peer-end (make-vector m 0)] [group (make-vector m 1)])
      ;; peer groups
      (do ([p 0 (+ p 1)]) ((= p m))
        (if (and (> p 0) (= 0 (compare-keys terms (vector-ref keys (- p 1)) (vector-ref keys p))))
            (begin (vector-set! peer-start p (vector-ref peer-start (- p 1)))
                   (vector-set! group p (vector-ref group (- p 1))))
            (begin (vector-set! peer-start p p)
                   (when (> p 0) (vector-set! group p (+ 1 (vector-ref group (- p 1))))))))
      (do ([p (- m 1) (- p 1)]) ((< p 0))
        (vector-set! peer-end p
                     (if (and (< (+ p 1) m) (= (vector-ref peer-start (+ p 1)) (vector-ref peer-start p)))
                         (vector-ref peer-end (+ p 1))
                         p)))
      (let ([ctx (vector m rows keys peer-start peer-end group)])
        (do ([p 0 (+ p 1)]) ((= p m))
          (vector-set! out (vector-ref idx p) (evaluate-at plan ctx p))))))

  (define (compare-keys terms ka kb)
    (let loop ([terms terms] [ka ka] [kb kb])
      (if (null? terms)
          0
          (let ([c (compare-for-sort (car ka) (car kb) (cadar terms) (caddar terms) (cadddr (car terms)))])
            (if (= c 0) (loop (cdr terms) (cdr ka) (cdr kb)) c)))))

  ;; ctx: #(size rows keys peer-start peer-end group-number), all indexed by position in the partition.
  (define-syntax ctx-size (syntax-rules () [(_ c) (vector-ref c 0)]))
  (define-syntax ctx-rows (syntax-rules () [(_ c) (vector-ref c 1)]))
  (define-syntax ctx-keys (syntax-rules () [(_ c) (vector-ref c 2)]))
  (define-syntax ctx-peer-start (syntax-rules () [(_ c) (vector-ref c 3)]))
  (define-syntax ctx-peer-end (syntax-rules () [(_ c) (vector-ref c 4)]))
  (define-syntax ctx-group (syntax-rules () [(_ c) (vector-ref c 5)]))

  (define (evaluate-at plan ctx p)
    (let* ([m (ctx-size ctx)] [row (vector-ref (ctx-rows ctx) p)]
           [args (wplan-args plan)])
      (define (arg k) ((list-ref args k) row))
      (define (arg-at k q) ((list-ref args k) (vector-ref (ctx-rows ctx) q)))
      (define (frame-value pick)
        (let-values ([(lo hi) (frame-bounds plan ctx p)])
          (if (> lo hi) sql-null (arg-at 0 (pick lo hi)))))
      (case (wplan-function plan)
        [(agg) (let-values ([(lo hi) (frame-bounds plan ctx p)])
                 (compute-aggregate (wplan-aggregate plan) (frame-rows ctx lo hi)))]
        [(row_number) (+ p 1)]
        [(rank) (+ 1 (vector-ref (ctx-peer-start ctx) p))]
        [(dense_rank) (vector-ref (ctx-group ctx) p)]
        [(percent_rank)
         (if (= m 1) 0.0 (inexact (/ (vector-ref (ctx-peer-start ctx) p) (- m 1))))]
        [(cume_dist) (inexact (/ (+ 1 (vector-ref (ctx-peer-end ctx) p)) m))]
        [(ntile) (ntile-bucket (arg 0) m p)]
        [(lag lead)
         (let* ([k (if (> (length args) 1) (arg 1) 1)]
                [sign (if (eq? (wplan-function plan) (quote lag)) -1 1)])
           (cond
             [(sql-null? k) sql-null]
             [else
              (let* ([n (to-number k)]
                     [q (+ p (* sign (if (flonum? n) (exact (truncate n)) n)))])
                (if (and (>= q 0) (< q m))
                    (arg-at 0 q)
                    (if (> (length args) 2) (arg 2) sql-null)))]))]
        [(first_value) (frame-value (lambda (lo hi) lo))]
        [(last_value) (frame-value (lambda (lo hi) hi))]
        [(nth_value)
         (let ([n (arg 1)])
           (unless (and (not (string? n)) (not (sql-null? n)) (integer? n) (>= n 1))
             (raise-sql-error "second argument to nth_value must be a positive integer"))
           (let-values ([(lo hi) (frame-bounds plan ctx p)])
             (let ([q (+ lo (- (exact n) 1))])
               (if (<= q hi) (arg-at 0 q) sql-null))))]
        [else (error 'evaluate-at "unknown window function" (wplan-function plan))])))

  ;; Bucket 1..n of the row at 0-based position p among m rows: sizes differ by at most 1, larger first.
  (define (ntile-bucket n m p)
    (unless (and (not (sql-null? n)) (not (string? n)) (integer? n) (>= n 1))
      (raise-sql-error "argument of ntile must be a positive integer"))
    (let* ([n (exact n)] [base (div m n)] [extra (mod m n)] [big (* extra (+ base 1))])
      (if (< p big)
          (+ 1 (div p (+ base 1)))
          (+ 1 extra (div (- p big) base)))))

  (define (frame-rows ctx lo hi)
    (let loop ([q hi] [acc '()])
      (if (< q lo) acc (loop (- q 1) (cons (vector-ref (ctx-rows ctx) q) acc)))))

  ;; ---- frames (6.2) ----

  ;; The first and last position of the frame of position p; lo > hi when it is empty.
  (define (frame-bounds plan ctx p)
    (let* ([m (ctx-size ctx)]
           [frame (or (wplan-frame plan)
                      (list 'range '(unbounded-preceding) '(current-row)))]
           [range? (eq? (car frame) 'range)])
      (values (max 0 (bound-position plan ctx p (cadr frame) range? #t))
              (min (- m 1) (bound-position plan ctx p (caddr frame) range? #f)))))

  ;; Position a frame bound stands for (not clipped to the partition); start?: it is the start.
  (define (bound-position plan ctx p bound range? start?)
    (let ([m (ctx-size ctx)])
      (case (car bound)
        [(unbounded-preceding) (if start? 0 -1)]
        [(unbounded-following) (if start? m (- m 1))]
        [(current-row)
         (if range?
             (vector-ref (if start? (ctx-peer-start ctx) (ctx-peer-end ctx)) p)
             p)]
        [else
         (let ([n (cadr bound)] [preceding? (eq? (car bound) 'preceding)])
           (if range?
               (range-offset-position plan ctx p n preceding? start?)
               (if preceding? (- p n) (+ p n))))])))

  ;; RANGE n PRECEDING / FOLLOWING: the first (start) or last (end) position whose ORDER BY value
  ;; is not before / after the current value moved by n. NULLs match only a NULL current value.
  (define (range-offset-position plan ctx p n preceding? start?)
    (let* ([term (car (wplan-order plan))] [desc? (cadr term)]
           [key-at (lambda (q) (car (vector-ref (ctx-keys ctx) q)))]
           [v (key-at p)] [m (ctx-size ctx)])
      (if (sql-null? v)
          (vector-ref (if start? (ctx-peer-start ctx) (ctx-peer-end ctx)) p)
          (let* ([down? (eq? preceding? (not desc?))]
                 [target (sql-arith (if down? 'minus 'plus) v n)]
                 [ok? (lambda (q)
                        (let ([k (key-at q)])
                          (and (not (sql-null? k))
                               (let ([c (compare-values k target (cadddr term))])
                                 (if (eq? start? (not desc?)) (>= c 0) (<= c 0))))))])
            (if start?
                (let loop ([q 0]) (cond [(= q m) m] [(ok? q) q] [else (loop (+ q 1))]))
                (let loop ([q (- m 1)]) (cond [(< q 0) -1] [(ok? q) q] [else (loop (- q 1))])))))))
  )
