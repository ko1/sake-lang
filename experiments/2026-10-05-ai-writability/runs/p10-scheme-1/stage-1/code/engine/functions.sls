;;; Scalar functions (1.11). Each entry: (min-args max-args-or-#f procedure on the argument values).
(library (engine functions)
  (export find-function function-min-args function-max-args function-proc)
  (import (rnrs) (engine value) (engine numeric))

  (define-record-type function (fields min-args max-args proc))

  (define (ascii-map f s) (list->string (map f (string->list s))))
  (define (ascii-upcase c) (if (char<=? #\a c #\z) (integer->char (- (char->integer c) 32)) c))
  (define (ascii-downcase c) (if (char<=? #\A c #\Z) (integer->char (+ (char->integer c) 32)) c))

  ;; A function that gives NULL when any argument is NULL.
  (define (strict f)
    (lambda args (if (exists sql-null? args) sql-null (apply f args))))

  (define (fn-abs x)
    (cond [(string? x) (abs (inexact (to-number x)))]
          [else (abs x)]))

  (define (fn-coalesce . args)
    (cond [(null? args) sql-null]
          [(sql-null? (car args)) (apply fn-coalesce (cdr args))]
          [else (car args)]))

  (define (fn-nullif x y)
    (if (and (not (sql-null? x)) (not (sql-null? y)) (= 0 (compare-values x y))) sql-null x))

  (define table
    (let ([h (make-hashtable string-hash string=?)])
      (for-each
       (lambda (e) (hashtable-set! h (car e) (apply make-function (cdr e))))
       (list
        (list "length" 1 1 (strict (lambda (x) (string-length (text-form x)))))
        (list "upper" 1 1 (strict (lambda (x) (ascii-map ascii-upcase (text-form x)))))
        (list "lower" 1 1 (strict (lambda (x) (ascii-map ascii-downcase (text-form x)))))
        (list "abs" 1 1 (strict fn-abs))
        (list "typeof" 1 1 type-name-lower)
        (list "coalesce" 2 #f fn-coalesce)
        (list "ifnull" 2 2 fn-coalesce)
        (list "nullif" 2 2 fn-nullif)))
      h))

  ;; The function with this lowercase name, or #f.
  (define (find-function lower) (hashtable-ref table lower #f)))
