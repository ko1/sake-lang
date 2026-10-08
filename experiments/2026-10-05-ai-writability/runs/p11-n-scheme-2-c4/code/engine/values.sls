;;; (engine values) -- SQL values and everything that is defined on a value alone.
;;;
;;; Representation:  NULL = the symbol `null`; INTEGER = exact integer;
;;; REAL = flonum; TEXT = string.  Spec sections 1.3, 1.5 (parsing), 1.9 (order), 1.10 (truth).
(library (engine values)
  (export sql-null sql-null? integer-value? real-value? text-value? number-value?
          int64-min int64-max normalize-integer real-whole-int64
          ascii-downcase ascii-upcase whitespace-char? digit-char?
          format-real decimal-exponent value->text value->display
          scan-numeric text->number text->number-prefix
          value-compare truth bool->value)
  (import (rnrs))

  ;;; ---- type predicates -------------------------------------------------

  (define sql-null 'null)
  (define (sql-null? v) (eq? v 'null))
  (define (integer-value? v) (and (integer? v) (exact? v)))
  (define (real-value? v) (and (real? v) (inexact? v)))
  (define (text-value? v) (string? v))
  (define (number-value? v) (or (integer-value? v) (real-value? v)))

  (define int64-min (- (expt 2 63)))
  (define int64-max (- (expt 2 63) 1))

  ;; An integer outside 64 bits is a REAL, as in SQLite.
  (define (normalize-integer n)
    (if (and (>= n int64-min) (<= n int64-max)) n (inexact n)))

  ;; The exact integer equal to REAL x if x is whole and fits in 64 bits, else #f.
  (define (real-whole-int64 x)
    (and (= x (floor x))
         (let ([n (exact x)]) (and (>= n int64-min) (<= n int64-max) n))))

  ;;; ---- ASCII text helpers ----------------------------------------------

  (define (ascii-map-chars proc s) (list->string (map proc (string->list s))))
  (define (ascii-downcase s)
    (ascii-map-chars (lambda (c) (if (and (char>=? c #\A) (char<=? c #\Z))
                                     (integer->char (+ (char->integer c) 32)) c)) s))
  (define (ascii-upcase s)
    (ascii-map-chars (lambda (c) (if (and (char>=? c #\a) (char<=? c #\z))
                                     (integer->char (- (char->integer c) 32)) c)) s))

  (define (whitespace-char? c)
    (or (char=? c #\space) (char=? c #\tab) (char=? c #\newline) (char=? c #\return)))
  (define (digit-char? c) (and (char>=? c #\0) (char<=? c #\9)))

  ;;; ---- printing (1.3) --------------------------------------------------

  ;; printf("%.15g") followed by the ".0" rules of the spec, via exact arithmetic.
  (define (format-real x)
    (if (= x 0.0)
        "0.0"
        (let* ([ax (abs (exact x))]
               [e (decimal-exponent ax (abs x))]
               [scaled (round (/ ax (expt 10 (- e 14))))]   ; round-half-even on the exact value
               [carry? (>= scaled (expt 10 15))]
               [digits (number->string (if carry? (div scaled 10) scaled))]
               [e (if carry? (+ e 1) e)]
               [body (if (or (< e -4) (>= e 15))
                         (exponent-form digits e)
                         (fixed-form digits e))])
          (if (< x 0.0) (string-append "-" body) body))))

  ;; floor(log10 ax) for exact positive ax; fl is the same number as a flonum (for the estimate).
  (define (decimal-exponent ax fl)
    (let loop ([e (exact (floor (/ (log fl) (log 10.0))))])
      (cond [(< ax (expt 10 e)) (loop (- e 1))]
            [(>= ax (expt 10 (+ e 1))) (loop (+ e 1))]
            [else e])))

  (define (strip-trailing-zeros s)
    (let loop ([n (string-length s)])
      (if (and (> n 0) (char=? (string-ref s (- n 1)) #\0)) (loop (- n 1)) (substring s 0 n))))

  (define (with-point int-part frac-part)
    (string-append int-part "." (if (string=? frac-part "") "0" frac-part)))

  (define (exponent-form digits e)
    (let ([ae (abs e)])
      (string-append (with-point (substring digits 0 1) (strip-trailing-zeros (substring digits 1 15)))
                     "e" (if (< e 0) "-" "+")
                     (if (< ae 10) "0" "") (number->string ae))))

  (define (fixed-form digits e)
    (if (>= e 0)
        (with-point (substring digits 0 (+ e 1))
                    (strip-trailing-zeros (substring digits (+ e 1) 15)))
        (with-point "0" (strip-trailing-zeros
                         (string-append (make-string (- (- e) 1) #\0) digits)))))

  ;; Text form (1.3) of a non-NULL value.
  (define (value->text v)
    (cond [(string? v) v]
          [(integer-value? v) (number->string v)]
          [else (format-real v)]))

  ;; What a result row prints.
  (define (value->display v) (if (sql-null? v) "NULL" (value->text v)))

  ;;; ---- numeric text (1.5 step 2, 1.8 numeric prefix) -------------------

  (define (scan-digits s i)
    (let ([n (string-length s)])
      (let loop ([i i]) (if (and (< i n) (digit-char? (string-ref s i))) (loop (+ i 1)) i))))

  ;; Longest numeric literal (optional sign) starting exactly at index `start`.
  ;; Returns (values number end); number is #f if there is none.  An integer
  ;; literal is returned as written (it may exceed 64 bits).
  (define (scan-numeric s start)
    (let* ([n (string-length s)]
           [char-at (lambda (i) (if (< i n) (string-ref s i) #\nul))]
           [sign? (memv (char-at start) '(#\+ #\-))]
           [i1 (if sign? (+ start 1) start)]
           [int-end (scan-digits s i1)]
           [dot? (char=? (char-at int-end) #\.)]
           [frac-start (if dot? (+ int-end 1) int-end)]
           [frac-end (scan-digits s frac-start)]
           [ndigits (+ (- int-end i1) (- frac-end frac-start))])
      (if (= ndigits 0)
          (values #f start)
          (let* ([e? (memv (char-at frac-end) '(#\e #\E))]
                 [esign? (and e? (memv (char-at (+ frac-end 1)) '(#\+ #\-)))]
                 [exp-start (+ frac-end (if esign? 2 1))]
                 [exp-end (if e? (scan-digits s exp-start) exp-start)]
                 [exp? (and e? (> exp-end exp-start))]
                 [end (if exp? exp-end frac-end)]
                 [mantissa (string->number (string-append (substring s i1 int-end)
                                                          (substring s frac-start frac-end)))]
                 [exponent (if exp?
                               (let ([v (string->number (substring s exp-start exp-end))])
                                 (if (and esign? (char=? (char-at (+ frac-end 1)) #\-)) (- v) v))
                               0)]
                 [negative? (and sign? (char=? (char-at start) #\-))]
                 [signed (if negative? (- mantissa) mantissa)])
            (if (or dot? exp?)
                (let ([scale (max -6000 (min 6000 (- exponent (- frac-end frac-start))))])
                  (values (inexact (* signed (expt 10 scale))) end))
                (values signed end))))))

  (define (skip-whitespace s i)
    (let ([n (string-length s)])
      (let loop ([i i]) (if (and (< i n) (whitespace-char? (string-ref s i))) (loop (+ i 1)) i))))

  (define (clamp-number v) (if (integer-value? v) (normalize-integer v) v))

  ;; The whole string (spaces around allowed) as a number, or #f.
  (define (text->number s)
    (let ([start (skip-whitespace s 0)])
      (let-values ([(num end) (scan-numeric s start)])
        (and num (= (skip-whitespace s end) (string-length s)) (clamp-number num)))))

  ;; Numeric prefix of a string; INTEGER 0 if there is none.
  (define (text->number-prefix s)
    (let-values ([(num end) (scan-numeric s (skip-whitespace s 0))])
      (if num (clamp-number num) 0)))

  ;;; ---- order of values (1.9) and truth (1.10) --------------------------

  (define (value-rank v) (cond [(sql-null? v) 0] [(string? v) 2] [else 1]))

  ;; -1, 0 or 1: NULL < numbers < text; text by character code.
  (define (value-compare a b)
    (let ([ra (value-rank a)] [rb (value-rank b)])
      (cond [(< ra rb) -1]
            [(> ra rb) 1]
            [(= ra 0) 0]
            [(= ra 1) (cond [(< a b) -1] [(> a b) 1] [else 0])]
            [else (cond [(string<? a b) -1] [(string=? a b) 0] [else 1])])))

  ;; #t, #f or 'unknown.
  (define (truth v)
    (cond [(sql-null? v) 'unknown]
          [(string? v) (truth (text->number-prefix v))]
          [else (not (= v 0))]))

  (define (bool->value b) (cond [(eq? b 'unknown) sql-null] [b 1] [else 0])))
