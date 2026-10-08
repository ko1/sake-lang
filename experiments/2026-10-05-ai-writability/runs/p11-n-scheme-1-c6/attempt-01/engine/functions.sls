;;; Scalar functions (1.11, 2.4). Each entry: (min-args max-args-or-#f procedure on the argument values).
(library (engine functions)
  (export find-function function-min-args function-max-args function-proc)
  (import (rnrs) (engine value) (engine numeric) (engine arith) (engine strings))

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

  ;; ---- math functions (7.1, 7.2) ----

  ;; An argument as a number (7.1): INTEGER / REAL as is, TEXT only if wholly a numeric literal; else #f.
  (define (math-arg v)
    (cond [(sql-null? v) #f]
          [(string? v) (parse-numeric-text v)]
          [else v]))

  ;; A math function: NULL when any argument is NULL or not convertible by 7.1.
  (define (math-fn f)
    (lambda args
      (let ([ns (map math-arg args)])
        (if (memq #f ns) sql-null (apply f ns)))))

  ;; ceil / floor / trunc: an INTEGER stays, a REAL gives a whole REAL.
  (define (rounder flop)
    (math-fn (lambda (x) (if (flonum? x) (flop x) x))))

  (define (finite? x) (and (= x x) (< (abs x) +inf.0)))

  ;; C's fmod, computed exactly on the operands; NULL for a zero y.
  (define fn-mod
    (math-fn
     (lambda (x y)
       (let ([a (inexact x)] [b (inexact y)])
         (if (or (= b 0.0) (not (finite? a)) (not (finite? b)))
             sql-null
             (let ([ea (exact a)] [eb (exact b)])
               (inexact (- ea (* eb (truncate (/ ea eb)))))))))))

  ;; NaN (a negative base with a fractional exponent) is not a real number: NULL.
  (define fn-pow
    (math-fn
     (lambda (x y)
       (let ([r (flexpt (inexact x) (inexact y))])
         (if (= r r) r sql-null)))))

  (define fn-sqrt
    (math-fn (lambda (x) (if (< x 0) sql-null (flsqrt (inexact x))))))

  (define (fn-coalesce . args)
    (cond [(null? args) sql-null]
          [(sql-null? (car args)) (apply fn-coalesce (cdr args))]
          [else (car args)]))

  (define (fn-nullif x y)
    (if (and (not (sql-null? x)) (not (sql-null? y)) (= 0 (compare-values x y))) sql-null x))

  ;; Argument as an exact integer (start / length of substr).
  (define (integer-arg v) (let ([n (to-number v)]) (if (flonum? n) (exact (truncate n)) n)))

  (define (fn-substr x start . len)
    (text-substr (text-form x) (integer-arg start) (and (pair? len) (integer-arg (car len)))))

  ;; trim / ltrim / rtrim with an optional set of characters.
  (define (trimmer mode)
    (lambda (x . chars)
      (text-trim (text-form x) (if (pair? chars) (text-form (car chars)) " ") mode)))

  (define (fn-round x . n) (sql-round x (if (pair? n) (car n) 0)))

  ;; max / min: NULL if any argument is NULL, else the first of the extreme values.
  (define (extreme better?)
    (lambda args
      (if (exists sql-null? args)
          sql-null
          (fold-left (lambda (best v) (if (better? (compare-values v best)) v best))
                     (car args) (cdr args)))))

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
        (list "nullif" 2 2 fn-nullif)
        (list "substr" 2 3 (strict fn-substr))
        (list "trim" 1 2 (strict (trimmer 'both)))
        (list "ltrim" 1 2 (strict (trimmer 'left)))
        (list "rtrim" 1 2 (strict (trimmer 'right)))
        (list "replace" 3 3 (strict (lambda (x from to) (text-replace (text-form x) (text-form from) (text-form to)))))
        (list "instr" 2 2 (strict (lambda (x y) (text-instr (text-form x) (text-form y)))))
        (list "round" 1 2 (strict fn-round))
        (list "ceil" 1 1 (rounder flceiling))
        (list "ceiling" 1 1 (rounder flceiling))
        (list "floor" 1 1 (rounder flfloor))
        (list "trunc" 1 1 (rounder fltruncate))
        (list "mod" 2 2 fn-mod)
        (list "pow" 2 2 fn-pow)
        (list "power" 2 2 fn-pow)
        (list "sqrt" 1 1 fn-sqrt)
        (list "pi" 0 0 (lambda () 3.141592653589793))
        (list "max" 2 #f (extreme (lambda (c) (> c 0))))
        (list "min" 2 #f (extreme (lambda (c) (< c 0))))))
      h))

  ;; The function with this lowercase name, or #f.
  (define (find-function lower) (hashtable-ref table lower #f)))
