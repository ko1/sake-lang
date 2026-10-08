;;; SQL values: NULL = the symbol null, INTEGER = exact integer, REAL = flonum, TEXT = string,
;;; BLOB = bytevector (7.1; never mutated once made).
;;; Text forms, order of values, affinity (1.9), truth (1.10) and storing into a column (1.5).
(library (engine value)
  (export sql-null sql-null? sql-integer? sql-real? sql-number? sql-blob? blob-hex latin1-blob
          type-name-upper type-name-lower text-form display-form to-number
          compare-values compare-for-sort value-key apply-affinity coerce-to-affinity compare-with-affinity truth bool->value store-convert)
  (import (rnrs) (engine numeric))

  (define sql-null 'null)
  (define (sql-null? v) (eq? v 'null))
  (define (sql-integer? v) (and (integer? v) (exact? v)))
  (define (sql-real? v) (flonum? v))
  (define (sql-number? v) (or (sql-integer? v) (flonum? v)))

  (define (sql-blob? v) (bytevector? v))

  (define (type-name-upper v)
    (cond [(sql-null? v) "NULL"] [(sql-integer? v) "INTEGER"] [(flonum? v) "REAL"]
          [(sql-blob? v) "BLOB"] [else "TEXT"]))
  (define (type-name-lower v)
    (cond [(sql-null? v) "null"] [(sql-integer? v) "integer"] [(flonum? v) "real"]
          [(sql-blob? v) "blob"] [else "text"]))

  ;; Two uppercase hexadecimal digits per byte.
  (define (blob-hex b)
    (let* ([n (bytevector-length b)] [s (make-string (* 2 n))] [digits "0123456789ABCDEF"])
      (do ([i 0 (+ i 1)]) ((= i n) s)
        (let ([byte (bytevector-u8-ref b i)])
          (string-set! s (* 2 i) (string-ref digits (div byte 16)))
          (string-set! s (+ (* 2 i) 1) (string-ref digits (mod byte 16)))))))

  ;; A BLOB's text form (7.1): one character per byte, so lengths and positions agree.
  (define (blob->text b)
    (let* ([n (bytevector-length b)] [s (make-string n)])
      (do ([i 0 (+ i 1)]) ((= i n) s)
        (string-set! s i (integer->char (bytevector-u8-ref b i))))))

  ;; The inverse of blob->text, for strings made of characters below 256.
  (define (latin1-blob s)
    (let* ([n (string-length s)] [b (make-bytevector n)])
      (do ([i 0 (+ i 1)]) ((= i n) b)
        (bytevector-u8-set! b i (char->integer (string-ref s i))))))

  ;; The text form of a non-NULL value.
  (define (text-form v)
    (cond [(string? v) v]
          [(sql-integer? v) (number->string v)]
          [(sql-blob? v) (blob->text v)]
          [else (format-real v)]))

  ;; What the result printer shows (1.3, 7.1): a BLOB is X'..', unlike its text form.
  (define (display-form v)
    (cond [(sql-null? v) "NULL"]
          [(sql-blob? v) (string-append "X'" (blob-hex v) "'")]
          [else (text-form v)]))

  ;; Non-NULL value read as a number (TEXT and BLOB by numeric prefix of the text form).
  (define (to-number v)
    (cond [(string? v) (numeric-prefix v)]
          [(sql-blob? v) (numeric-prefix (blob->text v))]
          [else v]))

  (define (bool->value b) (if b 1 0))

  ;; Truth of a value: 'null (unknown), #t or #f.
  (define (truth v)
    (if (sql-null? v) 'null (not (zero? (to-number v)))))

  ;; ---- order of values (1.9, 7.2): NULL < numbers < TEXT < BLOB ----
  (define (rank v) (cond [(sql-null? v) 0] [(string? v) 2] [(sql-blob? v) 3] [else 1]))

  ;; Bytes as unsigned values; a proper prefix comes first.
  (define (compare-blobs a b)
    (let ([na (bytevector-length a)] [nb (bytevector-length b)])
      (let loop ([i 0])
        (cond [(and (= i na) (= i nb)) 0]
              [(= i na) -1]
              [(= i nb) 1]
              [else (let ([x (bytevector-u8-ref a i)] [y (bytevector-u8-ref b i)])
                      (cond [(< x y) -1] [(> x y) 1] [else (loop (+ i 1))]))]))))

  ;; -1, 0 or 1.
  (define (compare-values a b)
    (let ([ra (rank a)] [rb (rank b)])
      (cond [(< ra rb) -1]
            [(> ra rb) 1]
            [(= ra 0) 0]
            [(= ra 1) (cond [(< a b) -1] [(> a b) 1] [else 0])]
            [(= ra 3) (compare-blobs a b)]
            [else (cond [(string<? a b) -1] [(string<? b a) 1] [else 0])])))

  ;; ORDER BY comparison (1.7) of two values under one term; NULLs sort by nulls-first?.
  (define (compare-for-sort x y descending? nulls-first?)
    (cond [(and (sql-null? x) (sql-null? y)) 0]
          [(sql-null? x) (if nulls-first? -1 1)]
          [(sql-null? y) (if nulls-first? 1 -1)]
          [else (let ([c (compare-values x y)]) (if descending? (- c) c))]))

  ;; A key that is equal? exactly when compare-values says two values are equal (for hashing).
  (define (value-key v)
    (if (and (flonum? v) (= v (floor v)) (< (abs v) 1e18)) (exact v) v))

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
  (define (compare-with-affinity x ax y ay)
    (and (not (sql-null? x)) (not (sql-null? y))
         (let-values ([(x2 y2) (apply-affinity x ax y ay)]) (compare-values x2 y2))))

  ;; ---- storing into a column (1.5) ----
  (define (whole-in-int64? x)
    (and (= x (floor x)) (>= x -9223372036854775808.0) (< x 9223372036854775808.0)))

  ;; type is 'integer, 'real, 'text or 'blob. Returns (values stored #f), or (values #f
  ;; rejected-type-name). A BLOB is never converted (7.3, 7.4): only a BLOB column takes one, and
  ;; a BLOB column takes only NULL and a BLOB.
  (define (store-convert type v)
    (cond
      [(sql-null? v) (values v #f)]
      [(eq? type 'blob)
       (cond [(sql-blob? v) (values v #f)]
             [(sql-integer? v) (values #f "INT")]
             [(flonum? v) (values #f "REAL")]
             [else (values #f "TEXT")])]
      [(sql-blob? v) (values #f "BLOB")]
      [else
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
            [else (values (text-form v) #f)]))])))
