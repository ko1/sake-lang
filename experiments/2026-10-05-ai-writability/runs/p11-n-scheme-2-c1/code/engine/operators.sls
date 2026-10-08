;;; (engine operators) -- the operators of spec 1.8 as functions on values, and the
;;; affinity rules of 1.9.  Nothing here knows about rows or syntax.
(library (engine operators)
  (export op-add op-sub op-mul op-div op-mod op-neg op-pos op-concat
          op-compare op-is op-not op-and op-or op-like op-in cast-value
          comparison-converters affinity-converter)
  (import (rnrs) (only (chezscheme) quotient remainder) (engine values) (engine strings))

  ;;; ---- arithmetic -----------------------------------------------------------

  (define (as-number v) (if (string? v) (text->number-prefix v) v))

  ;; NULL if either side is NULL; integer-op if both are INTEGER, else real-op on REALs.
  (define (arithmetic int-op real-op)
    (lambda (a b)
      (if (or (sql-null? a) (sql-null? b))
          sql-null
          (let ([x (as-number a)] [y (as-number b)])
            (if (and (integer-value? x) (integer-value? y))
                (int-op x y)
                (real-op (inexact x) (inexact y)))))))

  (define op-add (arithmetic + +))
  (define op-sub (arithmetic - -))
  (define op-mul (arithmetic * *))
  (define op-div
    (arithmetic (lambda (x y) (if (zero? y) sql-null (quotient x y)))
                (lambda (x y) (if (= y 0.0) sql-null (/ x y)))))
  (define op-mod
    (arithmetic (lambda (x y) (if (zero? y) sql-null (remainder x y)))
                (lambda (x y)
                  (let ([ix (exact (truncate x))] [iy (exact (truncate y))])
                    (if (zero? iy) sql-null (inexact (remainder ix iy)))))))

  (define (op-neg v) (if (sql-null? v) v (- (as-number v))))
  (define (op-pos v) v)

  (define (op-concat a b)
    (if (or (sql-null? a) (sql-null? b)) sql-null (string-append (value->text a) (value->text b))))

  ;;; ---- affinity (1.9) -----------------------------------------------------------

  (define (numeric-affinity? a) (memq a '(integer real)))

  ;; A numeric-looking text becomes that number; other values stay.
  (define (text-to-number v)
    (or (and (string? v) (text->number v)) v))
  (define (number-to-text v)
    (if (number-value? v) (value->text v) v))

  ;; Given the affinities (integer real text or #f) of the two operands of a
  ;; comparison: (values left-converter right-converter), each a procedure on
  ;; values or #f for "leave alone".
  (define (comparison-converters left right)
    (cond [(and (numeric-affinity? left) (not (numeric-affinity? right))) (values #f text-to-number)]
          [(and (numeric-affinity? right) (not (numeric-affinity? left))) (values text-to-number #f)]
          [(and (eq? left 'text) (not right)) (values #f number-to-text)]
          [(and (eq? right 'text) (not left)) (values number-to-text #f)]
          [else (values #f #f)]))

  ;; The converter applied to IN's list items for an x of this affinity (2.3), or #f.
  (define (affinity-converter affinity)
    (cond [(numeric-affinity? affinity) text-to-number]
          [(eq? affinity 'text) number-to-text]
          [else #f]))

  ;;; ---- comparison and logic ----------------------------------------------------

  ;; `test` maps value-compare's -1/0/1 to a boolean.  a and b are already converted; text
  ;; compares under the collation `coll` (7.4).
  (define (op-compare test a b coll)
    (if (or (sql-null? a) (sql-null? b))
        sql-null
        (bool->value (test (value-compare a b coll)))))

  ;; a IS b: like = but never NULL.
  (define (op-is a b coll)
    (cond [(and (sql-null? a) (sql-null? b)) 1]
          [(or (sql-null? a) (sql-null? b)) 0]
          [else (bool->value (zero? (value-compare a b coll)))]))

  (define (op-not v)
    (let ([t (truth v)]) (bool->value (if (eq? t 'unknown) t (not t)))))

  (define (op-and a b)
    (let ([x (truth a)] [y (truth b)])
      (bool->value (cond [(or (eq? x #f) (eq? y #f)) #f]
                         [(or (eq? x 'unknown) (eq? y 'unknown)) 'unknown]
                         [else #t]))))

  (define (op-or a b)
    (let ([x (truth a)] [y (truth b)])
      (bool->value (cond [(or (eq? x #t) (eq? y #t)) #t]
                         [(or (eq? x 'unknown) (eq? y 'unknown)) 'unknown]
                         [else #f]))))

  ;;; ---- LIKE, IN, CAST (2.3) ----------------------------------------------------

  (define (op-like a pattern)
    (if (or (sql-null? a) (sql-null? pattern))
        sql-null
        (bool->value (like-match? (value->text a) (value->text pattern)))))

  ;; x IN (items): both already converted.  1 if some item equals x (under `coll`), else NULL if
  ;; x or an item is NULL, else 0.
  (define (op-in x items coll)
    (cond [(null? items) 0]
          [(sql-null? x) sql-null]
          [(exists (lambda (i) (and (not (sql-null? i)) (zero? (value-compare x i coll)))) items) 1]
          [(exists sql-null? items) sql-null]
          [else 0]))

  (define (clamp-int64 n) (max int64-min (min int64-max n)))

  ;; TEXT to INTEGER: optional sign and digits after leading whitespace, else 0.
  (define (text->integer-prefix s)
    (let* ([n (string-length s)]
           [start (let loop ([i 0]) (if (and (< i n) (whitespace-char? (string-ref s i))) (loop (+ i 1)) i))]
           [sign? (and (< start n) (memv (string-ref s start) '(#\+ #\-)))]
           [digits-start (if sign? (+ start 1) start)]
           [digits-end (let loop ([i digits-start])
                         (if (and (< i n) (digit-char? (string-ref s i))) (loop (+ i 1)) i))])
      (if (= digits-end digits-start)
          0
          (let ([v (string->number (substring s digits-start digits-end))])
            (clamp-int64 (if (char=? (string-ref s start) #\-) (- v) v))))))

  ;; type: integer, real or text.
  (define (cast-value type v)
    (cond
      [(sql-null? v) v]
      [else
       (case type
         [(integer) (cond [(string? v) (text->integer-prefix v)]
                          [(integer-value? v) v]
                          [else (clamp-int64 (exact (truncate v)))])]
         [(real) (inexact (if (string? v) (text->number-prefix v) v))]
         [else (value->text v)])])))
