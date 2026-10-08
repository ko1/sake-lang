;;; (engine operators) -- the operators of spec 1.8 as functions on values, and the
;;; affinity rules of 1.9.  Nothing here knows about rows or syntax.
(library (engine operators)
  (export op-add op-sub op-mul op-div op-mod op-neg op-pos op-concat
          op-compare op-is op-not op-and op-or
          comparison-converters)
  (import (rnrs) (only (chezscheme) quotient remainder) (engine values))

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

  ;;; ---- comparison and logic ----------------------------------------------------

  ;; `test` maps value-compare's -1/0/1 to a boolean.  a and b are already converted.
  (define (op-compare test a b)
    (if (or (sql-null? a) (sql-null? b))
        sql-null
        (bool->value (test (value-compare a b)))))

  ;; a IS b: like = but never NULL.
  (define (op-is a b)
    (cond [(and (sql-null? a) (sql-null? b)) 1]
          [(or (sql-null? a) (sql-null? b)) 0]
          [else (bool->value (zero? (value-compare a b)))]))

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
                         [else #f])))))
