;;; SQL values: NULL = the symbol null, INTEGER = exact integer, REAL = flonum, TEXT = string.
;;; Text forms, order of values, affinity (1.9), truth (1.10) and storing into a column (1.5).
(library (engine value)
  (export sql-null sql-null? sql-integer? sql-real? sql-number?
          type-name-upper type-name-lower text-form display-form to-number
          collation-by-name compare-values compare-for-sort value-key apply-affinity coerce-to-affinity compare-with-affinity truth bool->value store-convert)
  (import (rnrs) (only (engine ast) name-text name-lower) (engine errors) (engine numeric))

  (define sql-null 'null)
  (define (sql-null? v) (eq? v 'null))
  (define (sql-integer? v) (and (integer? v) (exact? v)))
  (define (sql-real? v) (flonum? v))
  (define (sql-number? v) (or (sql-integer? v) (flonum? v)))

  (define (type-name-upper v)
    (cond [(sql-null? v) "NULL"] [(sql-integer? v) "INTEGER"] [(flonum? v) "REAL"] [else "TEXT"]))
  (define (type-name-lower v)
    (cond [(sql-null? v) "null"] [(sql-integer? v) "integer"] [(flonum? v) "real"] [else "text"]))

  ;; The text form of a non-NULL value.
  (define (text-form v)
    (cond [(string? v) v]
          [(sql-integer? v) (number->string v)]
          [else (format-real v)]))

  (define (display-form v) (if (sql-null? v) "NULL" (text-form v)))

  ;; Non-NULL value read as a number (TEXT by numeric prefix).
  (define (to-number v) (if (string? v) (numeric-prefix v) v))

  (define (bool->value b) (if b 1 0))

  ;; Truth of a value: 'null (unknown), #t or #f.
  (define (truth v)
    (if (sql-null? v) 'null (not (zero? (to-number v)))))

  ;; ---- order of values (1.9): NULL < numbers < TEXT ----
  (define (rank v) (cond [(sql-null? v) 0] [(string? v) 2] [else 1]))

  ;; ---- collations (7.1): a collation is the symbol binary, nocase or rtrim ----

  ;; The collation a `name` stands for; an unknown one is an error.
  (define (collation-by-name nm)
    (let ([lower (name-lower nm)])
      (cond [(string=? lower "binary") 'binary]
            [(string=? lower "nocase") 'nocase]
            [(string=? lower "rtrim") 'rtrim]
            [else (raise-sql-error (string-append "no such collation sequence: " (name-text nm)))])))

  (define (ascii-downcase-string s)
    (list->string
     (map (lambda (c) (if (char<=? #\A c #\Z) (integer->char (+ (char->integer c) 32)) c))
          (string->list s))))

  (define (rtrim-spaces s)
    (let loop ([n (string-length s)])
      (if (and (> n 0) (char=? (string-ref s (- n 1)) #\space))
          (loop (- n 1))
          (substring s 0 n))))

  ;; The text that stands for s under the collation (equal keys <=> equal under it, same order).
  (define (collation-key coll s)
    (case coll
      [(nocase) (ascii-downcase-string s)]
      [(rtrim) (rtrim-spaces s)]
      [else s]))

  ;; -1, 0 or 1. The optional third argument is the collation for TEXT against TEXT (default binary).
  (define (compare-values a b . rest)
    (let ([ra (rank a)] [rb (rank b)])
      (cond [(< ra rb) -1]
            [(> ra rb) 1]
            [(= ra 0) 0]
            [(= ra 1) (cond [(< a b) -1] [(> a b) 1] [else 0])]
            [else (let* ([coll (if (pair? rest) (car rest) 'binary)]
                         [x (collation-key coll a)] [y (collation-key coll b)])
                    (cond [(string<? x y) -1] [(string<? y x) 1] [else 0]))])))

  ;; ORDER BY comparison (1.7) of two values under one term; NULLs sort by nulls-first?. The optional
  ;; fifth argument is the term's collation.
  (define (compare-for-sort x y descending? nulls-first? . rest)
    (cond [(and (sql-null? x) (sql-null? y)) 0]
          [(sql-null? x) (if nulls-first? -1 1)]
          [(sql-null? y) (if nulls-first? 1 -1)]
          [else (let ([c (apply compare-values x y rest)]) (if descending? (- c) c))]))

  ;; A key that is equal? exactly when compare-values says two values are equal (for hashing).
  ;; The optional second argument is the collation for TEXT.
  (define (value-key v . rest)
    (cond [(string? v) (collation-key (if (pair? rest) (car rest) 'binary) v)]
          [(and (flonum? v) (= v (floor v)) (< (abs v) 1e18)) (exact v)]
          [else v]))

  ;; ---- affinity (1.9): ax, ay are 'integer 'real 'text or #f. Returns the converted pair. ----
  (define (numeric-affinity? a) (or (eq? a 'integer) (eq? a 'real)))
  (define (as-number v) (if (string? v) (or (parse-numeric-text v) v) v))
  (define (as-text v) (if (sql-number? v) (text-form v) v))

  (define (apply-affinity x ax y ay)
    (cond [(and (numeric-affinity? ax) (not (numeric-affinity? ay))) (values x (as-number y))]
          [(and (numeric-affinity? ay) (not (numeric-affinity? ax))) (values (as-number x) y)]
          [(and (eq? ax 'text) (not ay)) (values x (as-text y))]
          [(and (eq? ay 'text) (not ax)) (values (as-text x) y)]
          [else (values x y)]))

  ;; Converts v to the affinity a alone (used by IN, 2.3); a is 'integer 'real 'text or #f.
  (define (coerce-to-affinity v a)
    (cond [(numeric-affinity? a) (as-number v)]
          [(eq? a 'text) (as-text v)]
          [else v]))

  ;; -1, 0, 1 comparing x and y after affinity conversion, or #f if either is NULL (the `=` rule).
  ;; The optional fifth argument is the collation (7.4).
  (define (compare-with-affinity x ax y ay . rest)
    (and (not (sql-null? x)) (not (sql-null? y))
         (let-values ([(x2 y2) (apply-affinity x ax y ay)]) (apply compare-values x2 y2 rest))))

  ;; ---- storing into a column (1.5) ----
  (define (whole-in-int64? x)
    (and (= x (floor x)) (>= x -9223372036854775808.0) (< x 9223372036854775808.0)))

  ;; type is 'integer, 'real or 'text. Returns (values stored #f), or (values #f rejected-type-name).
  (define (store-convert type v)
    (if (sql-null? v)
        (values v #f)
        (let ([v (if (and (string? v) (not (eq? type 'text))) (or (parse-numeric-text v) v) v)])
          (case type
            [(integer)
             (cond [(sql-integer? v) (values v #f)]
                   [(and (flonum? v) (whole-in-int64? v)) (values (exact v) #f)]
                   [(flonum? v) (values #f "REAL")]
                   [else (values #f "TEXT")])]
            [(real)
             (cond [(sql-integer? v) (values (inexact v) #f)]
                   [(flonum? v) (values v #f)]
                   [else (values #f "TEXT")])]
            [else (values (text-form v) #f)])))))
