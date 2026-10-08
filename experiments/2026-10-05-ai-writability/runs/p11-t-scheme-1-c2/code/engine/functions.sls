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
    (cond [(not (sql-number? x)) (abs (inexact (to-number x)))]
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
    (let ([start (integer-arg start)] [len (and (pair? len) (integer-arg (car len)))])
      (if (sql-blob? x)
          (let-values ([(p end) (substr-range (bytevector-length x) start len)])
            (let ([out (make-bytevector (- end p))])
              (bytevector-copy! x p out 0 (- end p))
              out))
          (text-substr (text-form x) start len))))

  (define (fn-length x)
    (if (sql-blob? x) (bytevector-length x) (string-length (text-form x))))

  (define (fn-instr x y)
    (if (and (sql-blob? x) (sql-blob? y))
        (bytes-instr x y)
        (text-instr (text-form x) (text-form y))))

  ;; hex(x) (7.10): not strict; NULL gives ''.
  (define (fn-hex x)
    (cond [(sql-null? x) ""]
          [(sql-blob? x) (bytes->hex x)]
          [else (bytes->hex (string->utf8 (text-form x)))]))

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
        (list "length" 1 1 (strict fn-length))
        (list "upper" 1 1 (strict (lambda (x) (ascii-map ascii-upcase (text-form x)))))
        (list "lower" 1 1 (strict (lambda (x) (ascii-map ascii-downcase (text-form x)))))
        (list "abs" 1 1 (strict fn-abs))
        (list "hex" 1 1 fn-hex)
        (list "typeof" 1 1 type-name-lower)
        (list "coalesce" 2 #f fn-coalesce)
        (list "ifnull" 2 2 fn-coalesce)
        (list "nullif" 2 2 fn-nullif)
        (list "substr" 2 3 (strict fn-substr))
        (list "trim" 1 2 (strict (trimmer 'both)))
        (list "ltrim" 1 2 (strict (trimmer 'left)))
        (list "rtrim" 1 2 (strict (trimmer 'right)))
        (list "replace" 3 3 (strict (lambda (x from to) (text-replace (text-form x) (text-form from) (text-form to)))))
        (list "instr" 2 2 (strict fn-instr))
        (list "round" 1 2 (strict fn-round))
        (list "max" 2 #f (extreme (lambda (c) (> c 0))))
        (list "min" 2 #f (extreme (lambda (c) (< c 0))))))
      h))

  ;; The function with this lowercase name, or #f.
  (define (find-function lower) (hashtable-ref table lower #f)))
