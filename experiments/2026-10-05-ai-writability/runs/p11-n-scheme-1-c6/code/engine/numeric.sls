;;; Numbers as text: scanning numeric literals / prefixes (1.2, 1.8) and printing REALs (1.3).
(library (engine numeric)
  (export scan-number numeric-prefix parse-numeric-text normalize-number
          sql-space? format-real decimal-digits int64-min int64-max)
  (import (rnrs))

  (define int64-max 9223372036854775807)
  (define int64-min -9223372036854775808)

  (define (sql-space? c) (memv c '(#\space #\tab #\newline #\return)))

  ;; An integer outside 64 bits becomes a REAL (as SQLite does).
  (define (normalize-number x)
    (if (and (exact? x) (or (> x int64-max) (< x int64-min))) (inexact x) x))

  (define (digit-at? s i)
    (and (< i (string-length s)) (char<=? #\0 (string-ref s i) #\9)))

  (define (skip-digits s i) (if (digit-at? s i) (skip-digits s (+ i 1)) i))

  (define (digits->integer s start end)
    (let loop ([i start] [acc 0])
      (if (= i end)
          acc
          (loop (+ i 1) (+ (* acc 10) (- (char->integer (string-ref s i)) 48))))))

  ;; Scan an unsigned numeric literal at s[i..]. Returns (values number end), or (values #f i).
  ;; The number is an exact integer (not range-checked) or a flonum.
  (define (scan-number s i)
    (let* ([n (string-length s)]
           [int-end (skip-digits s i)]
           [has-dot (and (< int-end n) (char=? (string-ref s int-end) #\.))]
           [frac-start (if has-dot (+ int-end 1) int-end)]
           [frac-end (skip-digits s frac-start)])
      (if (and (= int-end i) (= frac-end frac-start))
          (values #f i)
          (let-values ([(exp-val end) (scan-exponent s frac-end)])
            (let ([mantissa (+ (* (digits->integer s i int-end) (expt 10 (- frac-end frac-start)))
                               (digits->integer s frac-start frac-end))])
              (if (or has-dot exp-val)
                  (let ([scale (max -5000 (min 5000 (- (or exp-val 0) (- frac-end frac-start))))])
                    (values (inexact (* mantissa (expt 10 scale))) end))
                  (values mantissa end)))))))

  ;; An exponent counts only if it has digits. Returns (values exponent-or-#f end).
  (define (scan-exponent s p)
    (let ([n (string-length s)])
      (if (and (< p n) (memv (string-ref s p) '(#\e #\E)))
          (let* ([q (+ p 1)]
                 [neg (and (< q n) (char=? (string-ref s q) #\-))]
                 [q2 (if (and (< q n) (memv (string-ref s q) '(#\+ #\-))) (+ q 1) q)]
                 [e2 (skip-digits s q2)])
            (if (> e2 q2)
                (let ([v (min 100000 (digits->integer s q2 e2))])
                  (values (if neg (- v) v) e2))
                (values #f p)))
          (values #f p))))

  (define (skip-space s i)
    (if (and (< i (string-length s)) (sql-space? (string-ref s i))) (skip-space s (+ i 1)) i))

  ;; Optional sign at s[i]. Returns (values negative? next-index).
  (define (scan-sign s i)
    (if (< i (string-length s))
        (case (string-ref s i)
          [(#\-) (values #t (+ i 1))]
          [(#\+) (values #f (+ i 1))]
          [else (values #f i)])
        (values #f i)))

  (define (apply-sign neg x) (normalize-number (if neg (- x) x)))

  ;; "Numeric prefix" (1.8): the number at the start of s, or INTEGER 0.
  (define (numeric-prefix s)
    (let-values ([(neg i) (scan-sign s (skip-space s 0))])
      (let-values ([(num end) (scan-number s i)])
        (if num (apply-sign neg num) 0))))

  ;; The whole of s (trimmed) is a numeric literal with optional sign (1.5 step 2): number or #f.
  (define (parse-numeric-text s)
    (let* ([n (string-length s)]
           [start (skip-space s 0)]
           [end (let loop ([e n])
                  (if (and (> e start) (sql-space? (string-ref s (- e 1)))) (loop (- e 1)) e))]
           [t (substring s start end)])
      (and (> (string-length t) 0)
           (let-values ([(neg i) (scan-sign t 0)])
             (let-values ([(num e) (scan-number t i)])
               (and num (= e (string-length t)) (apply-sign neg num)))))))

  ;; ---- printing a REAL as C's "%.15g", then the SQL fix-ups of 1.3 ----

  (define (pow10 e) (expt 10 e))

  ;; Exponent e with 10^e <= q < 10^(e+1), for exact rational q > 0.
  (define (decimal-exponent q)
    (let ([guess (exact (floor (/ (log (inexact q)) (log 10.0))))])
      (let loop ([e guess])
        (cond [(>= q (pow10 (+ e 1))) (loop (+ e 1))]
              [(< q (pow10 e)) (loop (- e 1))]
              [else e]))))

  (define (strip-trailing-zeros s)
    (let loop ([e (string-length s)])
      (if (and (> e 0) (char=? (string-ref s (- e 1)) #\0)) (loop (- e 1)) (substring s 0 e))))

  (define (zeros k) (make-string k #\0))

  ;; The k significant digits of exact q > 0 (rounded half-even, as C's printf does on the exact
  ;; binary value). Returns (values digit-string e) with q ~ d.ddd * 10^e.
  (define (decimal-digits q k)
    (let* ([e0 (decimal-exponent q)]
           [r0 (round (/ q (pow10 (- e0 (- k 1)))))]
           [carry (= r0 (pow10 k))])
      (values (number->string (if carry (pow10 (- k 1)) r0)) (if carry (+ e0 1) e0))))

  (define (format-real x)
    (if (= x 0.0)
        "0.0"
        (let-values ([(digits e) (decimal-digits (exact (abs x)) 15)])
          (let ([body (if (and (< e 15) (>= e -4))
                          (fixed-form digits e)
                          (exponent-form digits e))])
            (if (< x 0.0) (string-append "-" body) body)))))

  ;; digits is 15 characters; the value is d.ddd * 10^e.
  (define (fixed-form digits e)
    (let* ([int-part (if (>= e 0) (substring digits 0 (+ e 1)) "0")]
           [frac-raw (if (>= e 0)
                         (substring digits (+ e 1) 15)
                         (string-append (zeros (- (- e) 1)) digits))]
           [frac (strip-trailing-zeros frac-raw)])
      (if (string=? frac "")
          (string-append int-part ".0")
          (string-append int-part "." frac))))

  (define (exponent-form digits e)
    (let* ([frac (strip-trailing-zeros (substring digits 1 15))]
           [mant (string-append (substring digits 0 1) "." (if (string=? frac "") "0" frac))]
           [ae (number->string (abs e))])
      (string-append mant "e" (if (< e 0) "-" "+") (if (< (string-length ae) 2) "0" "") ae))))
