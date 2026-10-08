;;; Arithmetic, concatenation and unary minus (1.8). All of them return NULL for a NULL operand.
(library (engine arith)
  (export sql-arith sql-concat sql-negate)
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
    (if (sql-null? x) sql-null (normalize-number (- (to-number x))))))
