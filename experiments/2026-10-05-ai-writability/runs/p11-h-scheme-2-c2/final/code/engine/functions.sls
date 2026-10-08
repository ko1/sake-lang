;;; (engine functions) -- the scalar functions of spec 1.11 and 2.4.
;;;
;;; A function is looked up by lower-cased name and called with a list of
;;; argument values.  To add one, add a line to `function-table`.
(library (engine functions)
  (export find-function function-min-args function-max-args function-proc)
  (import (rnrs) (engine values) (engine strings))

  ;; max-args #f means "any number".
  (define-record-type function (fields min-args max-args proc))

  ;; Wrap a one-argument function so that NULL gives NULL.
  (define (null-propagating f) (lambda (args) (if (sql-null? (car args)) sql-null (f (car args)))))

  ;; Wrap a function of several arguments so that any NULL argument gives NULL.
  (define (null-propagating-all f)
    (lambda (args) (if (exists sql-null? args) sql-null (apply f args))))

  ;; TEXT, and a BLOB through its text form (7.5), read by numeric prefix; others unchanged.
  (define (numeric-arg v)
    (cond [(string? v) (text->number-prefix v)]
          [(bytevector? v) (text->number-prefix (blob->text v))]
          [else v]))

  ;; An argument read as an integer (TEXT by numeric prefix, REAL truncated).
  (define (arg->integer v)
    (let ([n (numeric-arg v)])
      (if (integer-value? n) n (exact (truncate n)))))

  ;; length counts a BLOB's bytes (7.6); the text form of a BLOB has one character per byte.
  (define (fn-length x) (string-length (value->text x)))
  (define (fn-upper x) (ascii-upcase (value->text x)))
  (define (fn-lower x) (ascii-downcase (value->text x)))
  (define (fn-abs x)
    (cond [(or (string? x) (bytevector? x)) (abs (inexact (numeric-arg x)))]
          [else (abs x)]))

  (define (fn-typeof args)
    (let ([v (car args)])
      (cond [(sql-null? v) "null"] [(string? v) "text"] [(bytevector? v) "blob"]
            [(integer-value? v) "integer"] [else "real"])))

  ;; hex(x): the bytes of a BLOB, or of any other value's text form; NULL gives ''.
  (define (fn-hex args)
    (let ([v (car args)])
      (cond [(sql-null? v) ""]
            [(bytevector? v) (blob->hex v)]
            [else (blob->hex (text->blob (value->text v)))])))

  (define (fn-coalesce args)
    (cond [(null? args) sql-null]
          [(sql-null? (car args)) (fn-coalesce (cdr args))]
          [else (car args)]))

  ;; Compared without affinity; NULL is never equal.
  (define (fn-nullif args)
    (let ([x (car args)] [y (cadr args)])
      (if (and (not (sql-null? x)) (not (sql-null? y)) (zero? (value-compare x y))) sql-null x)))

  ;;; ---- text functions (2.4) -------------------------------------------

  ;; On a BLOB the same rules apply to its bytes (one character each), and the result is a BLOB.
  (define (fn-substr x start . len)
    (let ([part (substr-text (value->text x) (arg->integer start)
                             (and (pair? len) (arg->integer (car len))))])
      (if (bytevector? x)
          (u8-list->bytevector (map char->integer (string->list part)))
          part)))

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
           [v (inexact (numeric-arg x))])
      (if (= v 0.0)
          0.0
          (let* ([ax (abs (exact v))]
                 [scale (expt 10 (- (decimal-exponent ax (abs v)) 16))]
                 [decimal (* (round (/ ax scale)) scale)]
                 [rounded (/ (floor (+ (* decimal (expt 10 n)) 1/2)) (expt 10 n))])
            (inexact (if (< v 0.0) (- rounded) rounded))))))

  (define function-table
    (let ([table (make-hashtable string-hash string=?)])
      (for-each (lambda (entry) (hashtable-set! table (car entry) (apply make-function (cdr entry))))
                (list (list "length" 1 1 (null-propagating fn-length))
                      (list "upper" 1 1 (null-propagating fn-upper))
                      (list "lower" 1 1 (null-propagating fn-lower))
                      (list "abs" 1 1 (null-propagating fn-abs))
                      (list "typeof" 1 1 fn-typeof)
                      (list "hex" 1 1 fn-hex)
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
                      (list "max" 2 #f (extremum positive?))
                      (list "min" 2 #f (extremum negative?))))
      table))

  (define (find-function lname) (hashtable-ref function-table lname #f)))
