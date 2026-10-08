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

  ;; concat: text forms of the non-NULL arguments; '' when all are NULL (never NULL).
  (define (fn-concat . args)
    (apply string-append (map text-form (filter (lambda (v) (not (sql-null? v))) args))))

  ;; concat_ws: NULL if sep is NULL; NULL x arguments are skipped without a separator.
  (define (fn-concat-ws sep . args)
    (if (sql-null? sep)
        sql-null
        (let ([parts (map text-form (filter (lambda (v) (not (sql-null? v))) args))] [s (text-form sep)])
          (if (null? parts)
              ""
              (apply string-append (car parts)
                     (map (lambda (p) (string-append s p)) (cdr parts)))))))

  ;; char: each argument is a code point.
  (define (fn-char . codes)
    (list->string (map (lambda (c) (integer->char (integer-arg c))) codes)))

  (define (fn-unicode x)
    (let ([s (text-form x)])
      (if (string=? s "") sql-null (char->integer (string-ref s 0)))))

  ;; sign: TEXT counts only if the whole trimmed text is a numeric literal (1.5 step 2), else NULL.
  (define (fn-sign x)
    (let ([n (if (string? x) (parse-numeric-text x) x)])
      (cond [(not n) sql-null]
            [(< n 0) -1]
            [(> n 0) 1]
            [else 0])))

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
        (list "concat" 1 #f fn-concat)
        (list "concat_ws" 2 #f fn-concat-ws)
        (list "char" 0 #f fn-char)
        (list "unicode" 1 1 (strict fn-unicode))
        (list "sign" 1 1 (strict fn-sign))
        (list "max" 2 #f (extreme (lambda (c) (> c 0))))
        (list "min" 2 #f (extreme (lambda (c) (< c 0))))))
      h))

  ;; The function with this lowercase name, or #f.
  (define (find-function lower) (hashtable-ref table lower #f)))
