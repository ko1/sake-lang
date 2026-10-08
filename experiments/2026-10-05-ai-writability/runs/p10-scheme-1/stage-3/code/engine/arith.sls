;;; Arithmetic, concatenation, unary minus (1.8) and round (2.4). All return NULL for a NULL operand.
(library (engine arith)
  (export sql-arith sql-concat sql-negate sql-round)
  (import (rnrs) (only (chezscheme) quotient remainder) (engine value) (engine numeric))

  ;; op is one of plus minus times divide modulo.
  (define (sql-arith op x y)
    (if (or (sql-null? x) (sql-null? y))
        sql-null
        (let ([a (to-number x)] [b (to-number y)])
          (if (and (sql-integer? a) (sql-integer? b))
              (integer-op op a b)
              (real-op op (inexact a) (inexact b))))))

  (define (integer-op op a b)
    (case op
      [(plus) (+ a b)]
      [(minus) (- a b)]
      [(times) (* a b)]
      [(divide) (if (zero? b) sql-null (quotient a b))]
      [else (if (zero? b) sql-null (remainder a b))]))

  (define (real-op op a b)
    (case op
      [(plus) (+ a b)]
      [(minus) (- a b)]
      [(times) (* a b)]
      [(divide) (if (= b 0.0) sql-null (/ a b))]
      [else ; % truncates both operands to integers
       (let ([ia (exact (truncate a))] [ib (exact (truncate b))])
         (if (zero? ib) sql-null (inexact (remainder ia ib))))]))

  (define (sql-concat x y)
    (if (or (sql-null? x) (sql-null? y))
        sql-null
        (string-append (text-form x) (text-form y))))

  (define (sql-negate x)
    (if (sql-null? x) sql-null (normalize-number (- (to-number x)))))

  ;; round(x, n) (2.4): round the 17-digit decimal form of x half away from zero; n >= 0.
  (define (sql-round x n)
    (if (or (sql-null? x) (sql-null? n))
        sql-null
        (let ([f (inexact (to-number x))]
              [digits (max 0 (exact (truncate (to-number n))))])
          (if (= f 0.0)
              0.0
              (let-values ([(ds e) (decimal-digits (exact (abs f)) 17)])
                (let* ([decimal (* (string->number ds) (expt 10 (- e 16)))]
                       [rounded (floor (+ (* decimal (expt 10 digits)) 1/2))]
                       [result (inexact (/ rounded (expt 10 digits)))])
                  (if (< f 0.0) (- result) result)))))))
)
