;;; (engine functions) -- the scalar functions of spec 1.11 and 2.4.
;;;
;;; A function is looked up by lower-cased name and called with a list of
;;; argument values.  To add one, add a line to `function-table`.
(library (engine functions)
  (export find-function function-min-args function-max-args function-proc)
  (import (rnrs) (only (rnrs arithmetic flonums) flexpt) (engine values) (engine strings))

  ;; max-args #f means "any number".
  (define-record-type function (fields min-args max-args proc))

  ;; Wrap a one-argument function so that NULL gives NULL.
  (define (null-propagating f) (lambda (args) (if (sql-null? (car args)) sql-null (f (car args)))))

  ;; Wrap a function of several arguments so that any NULL argument gives NULL.
  (define (null-propagating-all f)
    (lambda (args) (if (exists sql-null? args) sql-null (apply f args))))

  ;; An argument read as an integer (TEXT by numeric prefix, REAL truncated).
  (define (arg->integer v)
    (let ([n (if (string? v) (text->number-prefix v) v)])
      (if (integer-value? n) n (exact (truncate n)))))

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

  ;;; ---- text functions (2.4) -------------------------------------------

  (define (fn-substr x start . len)
    (substr-text (value->text x) (arg->integer start)
                 (and (pair? len) (arg->integer (car len)))))

  (define (trimmer left? right?)
    (lambda (x . chars)
      (trim-text (value->text x) (if (pair? chars) (value->text (car chars)) " ") left? right?)))

  (define (fn-replace x from to) (replace-text (value->text x) (value->text from) (value->text to)))

  (define (fn-instr x y)
    (let ([i (find-substring (value->text x) (value->text y) 0)])
      (if i (+ i 1) 0)))

  ;; The first of the extreme values; `better?` takes (candidate best).
  (define (extremum better?)
    (null-propagating-all
     (lambda args
       (fold-left (lambda (best v) (if (better? (value-compare v best)) v best)) (car args) (cdr args)))))

  ;; round(x [, n]): x's 17-significant-digit decimal form rounded half away from zero.
  (define (fn-round x . digits)
    (let* ([n (if (pair? digits) (max 0 (arg->integer (car digits))) 0)]
           [v (inexact (if (string? x) (text->number-prefix x) x))])
      (if (= v 0.0)
          0.0
          (let* ([ax (abs (exact v))]
                 [scale (expt 10 (- (decimal-exponent ax (abs v)) 16))]
                 [decimal (* (round (/ ax scale)) scale)]
                 [rounded (/ (floor (+ (* decimal (expt 10 n)) 1/2)) (expt 10 n))])
            (inexact (if (< v 0.0) (- rounded) rounded))))))

  ;;; ---- math functions (7) ---------------------------------------------

  ;; An argument as a number (7.1): TEXT only if it is wholly a numeric literal; else NULL.
  (define (arg->number v)
    (cond [(sql-null? v) sql-null]
          [(string? v) (or (text->number v) sql-null)]
          [else v]))

  ;; Wrap a function of numbers: any NULL or non-numeric-text argument gives NULL.
  (define (numeric-args f)
    (lambda (args)
      (let ([nums (map arg->number args)])
        (if (exists sql-null? nums) sql-null (apply f nums)))))

  ;; ceil/floor/trunc: an INTEGER is kept, a REAL stays a REAL.
  (define (keeping-integer round-real)
    (numeric-args (lambda (x) (if (integer-value? x) x (round-real x)))))

  ;; mod: C's fmod, exactly, on both as REAL; NULL for a zero divisor.
  (define (fn-mod x y)
    (let ([ex (exact (inexact x))] [ey (exact (inexact y))])
      (if (zero? ey)
          sql-null
          (inexact (- ex (* (truncate (/ ex ey)) ey))))))

  ;; pow: C's pow; NULL when the result is not a real number (NaN).
  (define (fn-pow x y)
    (let ([r (flexpt (inexact x) (inexact y))])
      (if (= r r) r sql-null)))

  (define (fn-sqrt x)
    (let ([v (inexact x)]) (if (< v 0.0) sql-null (sqrt v))))

  (define pi-value 3.141592653589793)

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
                      (list "nullif" 2 2 fn-nullif)
                      (list "substr" 2 3 (null-propagating-all fn-substr))
                      (list "trim" 1 2 (null-propagating-all (trimmer #t #t)))
                      (list "ltrim" 1 2 (null-propagating-all (trimmer #t #f)))
                      (list "rtrim" 1 2 (null-propagating-all (trimmer #f #t)))
                      (list "replace" 3 3 (null-propagating-all fn-replace))
                      (list "instr" 2 2 (null-propagating-all fn-instr))
                      (list "round" 1 2 (null-propagating-all fn-round))
                      (list "ceil" 1 1 (keeping-integer ceiling))
                      (list "ceiling" 1 1 (keeping-integer ceiling))
                      (list "floor" 1 1 (keeping-integer floor))
                      (list "trunc" 1 1 (keeping-integer truncate))
                      (list "mod" 2 2 (numeric-args fn-mod))
                      (list "pow" 2 2 (numeric-args fn-pow))
                      (list "power" 2 2 (numeric-args fn-pow))
                      (list "sqrt" 1 1 (numeric-args fn-sqrt))
                      (list "pi" 0 0 (lambda (args) pi-value))
                      (list "max" 2 #f (extremum positive?))
                      (list "min" 2 #f (extremum negative?))))
      table))

  (define (find-function lname) (hashtable-ref function-table lname #f)))
