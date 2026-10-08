;;; (engine functions) -- the scalar functions of spec 1.11.
;;;
;;; A function is looked up by lower-cased name and called with a list of
;;; argument values.  To add one, add a line to `function-table`.
(library (engine functions)
  (export find-function function-min-args function-max-args function-proc)
  (import (rnrs) (engine values))

  ;; max-args #f means "any number".
  (define-record-type function (fields min-args max-args proc))

  ;; Wrap a one-argument function so that NULL gives NULL.
  (define (null-propagating f) (lambda (args) (if (sql-null? (car args)) sql-null (f (car args)))))

  (define (fn-length x) (string-length (value->text x)))
  (define (fn-upper x) (ascii-upcase (value->text x)))
  (define (fn-lower x) (ascii-downcase (value->text x)))
  (define (fn-abs x)
    (cond [(string? x) (abs (inexact (text->number-prefix x)))]
          [else (abs x)]))

  (define (fn-typeof args)
    (let ([v (car args)])
      (cond [(sql-null? v) "null"] [(string? v) "text"] [(integer-value? v) "integer"] [else "real"])))

  (define (fn-coalesce args)
    (cond [(null? args) sql-null]
          [(sql-null? (car args)) (fn-coalesce (cdr args))]
          [else (car args)]))

  ;; Compared without affinity; NULL is never equal.
  (define (fn-nullif args)
    (let ([x (car args)] [y (cadr args)])
      (if (and (not (sql-null? x)) (not (sql-null? y)) (zero? (value-compare x y))) sql-null x)))

  (define function-table
    (let ([table (make-hashtable string-hash string=?)])
      (for-each (lambda (entry) (hashtable-set! table (car entry) (apply make-function (cdr entry))))
                (list (list "length" 1 1 (null-propagating fn-length))
                      (list "upper" 1 1 (null-propagating fn-upper))
                      (list "lower" 1 1 (null-propagating fn-lower))
                      (list "abs" 1 1 (null-propagating fn-abs))
                      (list "typeof" 1 1 fn-typeof)
                      (list "coalesce" 2 #f fn-coalesce)
                      (list "ifnull" 2 2 fn-coalesce)
                      (list "nullif" 2 2 fn-nullif)))
      table))

  (define (find-function lname) (hashtable-ref function-table lname #f)))
