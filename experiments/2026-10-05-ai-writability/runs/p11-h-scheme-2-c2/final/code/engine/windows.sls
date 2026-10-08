;;; (engine windows) -- window functions (spec stage 6): resolving a window-spec, checking its
;;; frame, and computing the calls of one query over its rows.
;;;
;;; Like aggregates, a window call is compiled (in (engine expr)) into a read of a slot: the
;;; executor appends one value per registered call to every row, after the aggregation, and
;;; before DISTINCT / ORDER BY / LIMIT.  A call's slot is counted from the end of the row, so
;;; it does not depend on how many aggregate slots the row has.
(library (engine windows)
  (export make-window-collector window-collector? window-collector-definitions
          window-collector-calls window-collector-register! window-collector-take-used!
          window-collector-note-used!
          window-function-name? window-function-arity
          resolve-window-spec normalize-frame
          make-window-call append-window-values)
  (import (rnrs) (engine errors) (engine values) (engine ast) (engine aggregates)
          (engine ordering) (engine grouping))

  ;;; ---- the calls of a query ---------------------------------------------------------

  ;; definitions: alist lower-cased window name -> window-spec (the WINDOW clause).
  ;; calls: the window-calls registered so far, in slot order.  used: names since the last take.
  (define-record-type window-collector (fields definitions (mutable calls) (mutable used))
    (protocol (lambda (new) (lambda (clause)
                              (new (map (lambda (d) (cons (ascii-downcase (car d)) (cdr d))) clause)
                                   '() '())))))

  ;; The slot number (from the first window slot) of the new call.
  (define (window-collector-register! c call)
    (let ([k (length (window-collector-calls c))])
      (window-collector-calls-set! c (append (window-collector-calls c) (list call)))
      k))

  (define (window-collector-note-used! c name)
    (window-collector-used-set! c (cons name (window-collector-used c))))

  (define (window-collector-take-used! c)
    (let ([used (reverse (window-collector-used c))])
      (window-collector-used-set! c '())
      used))

  ;; kind: a window-only function's lower-case name (symbol) or an `aggregate`.
  ;; args, partition, order-procs: procedures of a row; order-terms: order-term records;
  ;; frame: (mode start end), see normalize-frame.
  (define-record-type window-call
    (fields kind star? args partition order-terms order-procs frame))

  ;;; ---- the window-only functions ------------------------------------------------------

  ;; name -> (min-args . max-args)
  (define window-functions
    '(("row_number" 0 . 0) ("rank" 0 . 0) ("dense_rank" 0 . 0) ("percent_rank" 0 . 0)
      ("cume_dist" 0 . 0) ("ntile" 1 . 1) ("lag" 1 . 3) ("lead" 1 . 3)
      ("first_value" 1 . 1) ("last_value" 1 . 1) ("nth_value" 2 . 2)))

  (define (window-function-name? lname) (and (assoc lname window-functions) #t))
  (define (window-function-arity lname) (cdr (assoc lname window-functions)))

  ;;; ---- window-specs and frames (6.1, 6.2) ----------------------------------------------

  ;; The (partition order frame) of an OVER clause: `over` is a window name or a window-spec;
  ;; a spec adds its own parts to those of its base window.
  (define (resolve-window-spec definitions over)
    (let resolve ([over over] [depth 0])
      (when (> depth 50) (raise-sql-error "circular window definition"))
      (cond
        [(string? over)
         (let ([d (assoc (ascii-downcase over) definitions)])
           (unless d (raise-sql-error (string-append "no such window: " over)))
           (resolve (cdr d) (+ depth 1)))]
        [else
         (let* ([base (if (cadr over) (resolve (cadr over) (+ depth 1)) (list '() '() #f))]
                [own (cddr over)])   ; (partition order frame)
           (list (if (null? (car own)) (car base) (car own))
                 (if (null? (cadr own)) (cadr base) (cadr own))
                 (or (caddr own) (caddr base))))])))

  (define (bound-kind b) (car b))
  (define (bound-offset b) (cadr b))
  (define (offset-bound? b) (memq (bound-kind b) '(preceding following)))

  ;; The frame as (mode start end), the default filled in, or an error.  nterms: the number
  ;; of ORDER BY terms of the window.
  (define (normalize-frame frame nterms)
    (let* ([frame (or frame (list 'range '(unbounded-preceding) '(current)))]
           [mode (car frame)] [start (cadr frame)] [end (caddr frame)]
           [sk (bound-kind start)] [ek (bound-kind end)])
      (when (or (and (eq? sk 'current) (eq? ek 'preceding))
                (and (eq? sk 'following) (memq ek '(current preceding)))
                (eq? sk 'unbounded-following)
                (eq? ek 'unbounded-preceding))
        (raise-sql-error "unsupported frame specification"))
      (check-offset mode start "starting")
      (check-offset mode end "ending")
      (when (and (eq? mode 'range) (or (offset-bound? start) (offset-bound? end)) (not (= nterms 1)))
        (raise-sql-error "RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression"))
      frame))

  (define (check-offset mode bound which)
    (when (offset-bound? bound)
      (let ([n (bound-offset bound)])
        (unless (if (eq? mode 'rows) (and (integer-value? n) (>= n 0)) (and (number? n) (>= n 0)))
          (raise-sql-error (string-append "frame " which " offset must be a non-negative "
                                          (if (eq? mode 'rows) "integer" "number")))))))

  ;;; ---- one partition ------------------------------------------------------------------

  ;; The sorted rows of a partition with what the functions need to know about it.
  ;; keys: vector of order-key lists; peer-start/peer-end: first/last position of the row's
  ;; peers; ids: each row's index in the query's rows; group: the row's peer group number (0-based); desc?: first ORDER BY term descending.
  (define-record-type part (fields rows ids keys peer-start peer-end group desc?))

  (define (part-size ctx) (vector-length (part-rows ctx)))

  (define (make-part-of call tagged)
    (let* ([terms (window-call-order-terms call)]
           [procs (window-call-order-procs call)]
           [entries (list-sort (lambda (x y) (< (compare-keys terms (car x) (car y)) 0))
                               (map (lambda (t) (cons (map (lambda (p) (p (car t))) procs) t)) tagged))]
           [keys (list->vector (map car entries))]
           [m (vector-length keys)]
           [peer-start (make-vector m 0)] [peer-end (make-vector m 0)] [group (make-vector m 0)])
      (let loop ([j 0] [start 0] [g -1])
        (when (< j m)
          (let* ([new? (or (= j 0) (not (zero? (compare-keys terms (vector-ref keys (- j 1)) (vector-ref keys j)))))]
                 [start (if new? j start)] [g (if new? (+ g 1) g)])
            (vector-set! peer-start j start)
            (vector-set! group j g)
            (loop (+ j 1) start g))))
      (let loop ([j (- m 1)] [end (- m 1)])
        (when (>= j 0)
          (let ([end (if (and (< (+ j 1) m) (= (vector-ref peer-start (+ j 1)) (vector-ref peer-start j)))
                         end j)])
            (vector-set! peer-end j end)
            (loop (- j 1) end))))
      (make-part (list->vector (map cadr entries)) (list->vector (map cddr entries)) keys peer-start peer-end group
                 (and (pair? terms) (eq? (order-term-direction (car terms)) 'desc)))))

  ;;; ---- the frame ----------------------------------------------------------------------

  ;; RANGE with an offset: the row bound is the current value moved by `d` in the order's
  ;; direction.  NULLs stay out of it, but a NULL current row has its peers as bound.
  (define (current-value ctx pos) (car (vector-ref (part-keys ctx) pos)))
  (define (bound-value ctx pos d)
    (let ([v (current-value ctx pos)])
      (and (number-value? v) (if (part-desc? ctx) (- v d) (+ v d)))))
  (define (key-at ctx j) (car (vector-ref (part-keys ctx) j)))

  ;; First position whose value is not before the bound.
  (define (range-first ctx pos d)
    (let ([b (bound-value ctx pos d)] [m (part-size ctx)])
      (if (not b)
          (vector-ref (part-peer-start ctx) pos)
          (let loop ([j 0])
            (cond [(= j m) m]
                  [(let ([v (key-at ctx j)])
                     (and (number-value? v)
                          (let ([c (value-compare v b)]) (if (part-desc? ctx) (<= c 0) (>= c 0)))))
                   j]
                  [else (loop (+ j 1))])))))

  ;; Last position whose value is not after the bound.
  (define (range-last ctx pos d)
    (let ([b (bound-value ctx pos d)] [m (part-size ctx)])
      (if (not b)
          (vector-ref (part-peer-end ctx) pos)
          (let loop ([j (- m 1)])
            (cond [(< j 0) -1]
                  [(let ([v (key-at ctx j)])
                     (and (number-value? v)
                          (let ([c (value-compare v b)]) (if (part-desc? ctx) (>= c 0) (<= c 0)))))
                   j]
                  [else (loop (- j 1))])))))

  ;; (values first last) of the frame of the row at `pos`, clipped to the partition; the
  ;; frame is empty when first > last.
  (define (frame-bounds frame ctx pos)
    (let* ([mode (car frame)] [start (cadr frame)] [end (caddr frame)] [m (part-size ctx)]
           [rows? (eq? mode 'rows)])
      (define (position bound start?)
        (let ([n (and (offset-bound? bound) (bound-offset bound))])
          (case (bound-kind bound)
            [(unbounded-preceding) 0]
            [(unbounded-following) (if start? m (- m 1))]
            [(current) (cond [rows? pos]
                             [start? (vector-ref (part-peer-start ctx) pos)]
                             [else (vector-ref (part-peer-end ctx) pos)])]
            [(preceding) (cond [rows? (- pos n)]
                               [start? (range-first ctx pos (- n))]
                               [else (range-last ctx pos (- n))])]
            [else (cond [rows? (+ pos n)]
                        [start? (range-first ctx pos n)]
                        [else (range-last ctx pos n)])])))
      (values (max 0 (position start #t)) (min (- m 1) (position end #f)))))

  ;;; ---- the functions -----------------------------------------------------------------------

  ;; The integer a numeric argument stands for (text by its numeric prefix, REAL truncated).
  (define (to-integer v)
    (cond [(integer-value? v) v]
          [(and (real-value? v) (= v v) (< (abs v) 1e300)) (exact (truncate v))]
          [(string? v) (to-integer (text->number-prefix v))]
          [(bytevector? v) (to-integer (text->number-prefix (blob->text v)))]
          [else 0]))

  ;; The integer a value is exactly, or #f.
  (define (exact-integer-of v)
    (cond [(integer-value? v) v]
          [(and (real-value? v) (= v v) (< (abs v) 1e300) (= v (floor v))) (exact v)]
          [(string? v) (let ([n (text->number v)]) (and n (exact-integer-of n)))]
          [(bytevector? v) (exact-integer-of (blob->text v))]
          [else #f]))

  ;; Bucket (1-based) of position `pos` when m rows are split into n buckets, larger first.
  (define (ntile-bucket pos m n)
    (let* ([q (div m n)] [r (mod m n)] [big (* r (+ q 1))])
      (if (< pos big)
          (+ 1 (div pos (+ q 1)))
          (+ 1 r (div (- pos big) q)))))

  ;; The value of the call for the row at `pos` of the partition.
  (define (call-value call ctx pos)
    (let* ([rows (part-rows ctx)] [row (vector-ref rows pos)] [m (part-size ctx)]
           [args (window-call-args call)]
           [arg (lambda (i) ((list-ref args i) row))]
           [kind (window-call-kind call)])
      (define (shifted direction)
        (let* ([k (if (pair? (cdr args)) (arg 1) 1)])
          (if (sql-null? k)
              sql-null
              (let ([j (+ pos (* direction (to-integer k)))])
                (cond [(and (>= j 0) (< j m)) ((car args) (vector-ref rows j))]
                      [(= (length args) 3) (arg 2)]
                      [else sql-null])))))
      (define (in-frame)
        (frame-bounds (window-call-frame call) ctx pos))
      (if (symbol? kind)
          (case kind
            [(row_number) (+ pos 1)]
            [(rank) (+ 1 (vector-ref (part-peer-start ctx) pos))]
            [(dense_rank) (+ 1 (vector-ref (part-group ctx) pos))]
            [(percent_rank) (if (= m 1)
                                0.0
                                (/ (inexact (vector-ref (part-peer-start ctx) pos)) (inexact (- m 1))))]
            [(cume_dist) (/ (inexact (+ 1 (vector-ref (part-peer-end ctx) pos))) (inexact m))]
            [(ntile) (let ([n (arg 0)])
                       (when (or (sql-null? n) (<= (to-integer n) 0))
                         (raise-sql-error "argument of ntile must be a positive integer"))
                       (ntile-bucket pos m (to-integer n)))]
            [(lag) (shifted -1)]
            [(lead) (shifted 1)]
            [(first_value) (let-values ([(lo hi) (in-frame)])
                             (if (> lo hi) sql-null ((car args) (vector-ref rows lo))))]
            [(last_value) (let-values ([(lo hi) (in-frame)])
                            (if (> lo hi) sql-null ((car args) (vector-ref rows hi))))]
            [(nth_value) (let* ([n (exact-integer-of (arg 1))])
                           (unless (and n (>= n 1))
                             (raise-sql-error "second argument to nth_value must be a positive integer"))
                           (let-values ([(lo hi) (in-frame)])
                             (if (> (+ lo (- n 1)) hi) sql-null ((car args) (vector-ref rows (+ lo (- n 1)))))))]
            [else (error 'call-value "unknown window function" kind)])
          ;; an aggregate over the frame, rows added in partition order
          (let-values ([(lo hi) (in-frame)])
            (aggregate-compute kind (window-call-star? call) #f
                               (let loop ([j hi] [acc '()])
                                 (if (< j lo)
                                     acc
                                     (let ([r (vector-ref rows j)])
                                       (loop (- j 1) (cons (map (lambda (p) (p r)) args) acc))))))))))

  ;;; ---- a call over all rows ---------------------------------------------------------------------

  ;; A vector of the call's value for each of `rows` (a vector), by the row's index.
  (define (compute-call call rows)
    (let* ([n (vector-length rows)]
           [out (make-vector n sql-null)]
           [indices (let loop ([i (- n 1)] [acc '()]) (if (< i 0) acc (loop (- i 1) (cons i acc))))]
           [partitions (partition-rows
                        (lambda (i) (map (lambda (p) (p (vector-ref rows i))) (window-call-partition call)))
                        indices)])
      (for-each
       (lambda (indices)
         (let ([ctx (make-part-of call (map (lambda (i) (cons (vector-ref rows i) i)) indices))])
           (do ([pos 0 (+ pos 1)]) ((= pos (part-size ctx)))
             (vector-set! out (vector-ref (part-ids ctx) pos) (call-value call ctx pos)))))
       partitions)
      out))

  ;; The rows (a list of vectors), each with the value of every call appended, same order.
  (define (append-window-values calls rows)
    (let* ([rows-vec (list->vector rows)]
           [columns (map (lambda (call) (compute-call call rows-vec)) calls)])
      (let loop ([i (- (vector-length rows-vec) 1)] [acc '()])
        (if (< i 0)
            acc
            (loop (- i 1)
                  (cons (list->vector (append (vector->list (vector-ref rows-vec i))
                                              (map (lambda (c) (vector-ref c i)) columns)))
                        acc)))))))
