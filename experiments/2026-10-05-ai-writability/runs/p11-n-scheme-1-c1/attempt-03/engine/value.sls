;;; SQL values: NULL = the symbol null, INTEGER = exact integer, REAL = flonum, TEXT = string.
;;; Text forms, order of values, affinity (1.9), truth (1.10) and storing into a column (1.5).
(library (engine value)
  (export sql-null sql-null? sql-integer? sql-real? sql-number?
          type-name-upper type-name-lower text-form display-form to-number
          compare-values compare-values-under compare-for-sort value-key value-key-under
          collation-symbol declared-collation collate-string pick-collation implicit-collation-info
          apply-affinity coerce-to-affinity compare-with-affinity truth bool->value store-convert)
  (import (rnrs) (engine numeric) (engine errors) (only (engine ast) name-text name-lower))

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

  ;; ---- collations (7): a collation is the symbol binary, nocase or rtrim ----

  ;; The collation named by a `name` (case-insensitive), or the error of 7.2.
  (define (collation-symbol nm)
    (let ([lower (name-lower nm)])
      (cond [(string=? lower "binary") 'binary]
            [(string=? lower "nocase") 'nocase]
            [(string=? lower "rtrim") 'rtrim]
            [else (raise-sql-error (string-append "no such collation sequence: " (name-text nm)))])))

  ;; The collation a declaration with this name (or #f for none) gives: binary by default.
  (define (declared-collation nm) (if nm (collation-symbol nm) 'binary))

  (define (ascii-lower-string s)
    (list->string
     (map (lambda (c) (if (char<=? #\A c #\Z) (integer->char (+ (char->integer c) 32)) c))
          (string->list s))))

  (define (trim-trailing-spaces s)
    (let loop ([n (string-length s)])
      (if (and (> n 0) (char=? (string-ref s (- n 1)) #\space))
          (loop (- n 1))
          (substring s 0 n))))

  ;; The TEXT s as it compares under coll: two strings are equal under coll exactly when their
  ;; collate-string results are string=?, and they order as those results do.
  (define (collate-string s coll)
    (case coll
      [(nocase) (ascii-lower-string s)]
      [(rtrim) (trim-trailing-spaces s)]
      [else s]))

  ;; A collation "info" says where an expression's collation came from: (explicit . coll) or
  ;; (implicit . coll). The collation of a comparison `a op b` (7.4) from the infos of a and b
  ;; (each an info or #f for none): explicit left, explicit right, implicit left, implicit right,
  ;; else binary.
  (define (pick-collation ia ib)
    (cond [(and ia (eq? (car ia) 'explicit)) (cdr ia)]
          [(and ib (eq? (car ib) 'explicit)) (cdr ib)]
          [ia (cdr ia)]
          [ib (cdr ib)]
          [else 'binary]))

  ;; The info of a column read from a source: whatever its stored info (or none), as an implicit one.
  (define (implicit-collation-info stored)
    (cons 'implicit (if stored (cdr stored) 'binary)))

  ;; -1, 0 or 1; TEXT values compare under coll.
  (define (compare-values-under a b coll)
    (let ([ra (rank a)] [rb (rank b)])
      (cond [(< ra rb) -1]
            [(> ra rb) 1]
            [(= ra 0) 0]
            [(= ra 1) (cond [(< a b) -1] [(> a b) 1] [else 0])]
            [else (let ([a (collate-string a coll)] [b (collate-string b coll)])
                    (cond [(string<? a b) -1] [(string<? b a) 1] [else 0]))])))

  ;; -1, 0 or 1, TEXT compared as BINARY.
  (define (compare-values a b) (compare-values-under a b 'binary))

  ;; ORDER BY comparison (1.7) of two values under one term; NULLs sort by nulls-first?. TEXT
  ;; compares under coll.
  (define (compare-for-sort x y descending? nulls-first? coll)
    (cond [(and (sql-null? x) (sql-null? y)) 0]
          [(sql-null? x) (if nulls-first? -1 1)]
          [(sql-null? y) (if nulls-first? 1 -1)]
          [else (let ([c (compare-values-under x y coll)]) (if descending? (- c) c))]))

  ;; A key that is equal? exactly when compare-values says two values are equal (for hashing).
  (define (value-key v)
    (if (and (flonum? v) (= v (floor v)) (< (abs v) 1e18)) (exact v) v))

  ;; Likewise under the collation coll.
  (define (value-key-under v coll)
    (value-key (if (string? v) (collate-string v coll) v)))

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

  ;; -1, 0, 1 comparing x and y after affinity conversion (TEXT under coll), or #f if either is
  ;; NULL (the `=` rule).
  (define (compare-with-affinity x ax y ay coll)
    (and (not (sql-null? x)) (not (sql-null? y))
         (let-values ([(x2 y2) (apply-affinity x ax y ay)]) (compare-values-under x2 y2 coll))))

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
