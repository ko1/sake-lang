;;; SQL values: NULL = the symbol null, INTEGER = exact integer, REAL = flonum, TEXT = string.
;;; Text forms, order of values, affinity (1.9), truth (1.10) and storing into a column (1.5).
(library (engine value)
  (export sql-null sql-null? sql-integer? sql-real? sql-number?
          type-name-upper type-name-lower text-form display-form to-number
          compare-values apply-affinity truth bool->value store-convert)
  (import (rnrs) (engine numeric))

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

  ;; -1, 0 or 1.
  (define (compare-values a b)
    (let ([ra (rank a)] [rb (rank b)])
      (cond [(< ra rb) -1]
            [(> ra rb) 1]
            [(= ra 0) 0]
            [(= ra 1) (cond [(< a b) -1] [(> a b) 1] [else 0])]
            [else (cond [(string<? a b) -1] [(string<? b a) 1] [else 0])])))

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
