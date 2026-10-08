;;; CAST(x AS type) (2.3).
(library (engine cast)
  (export sql-cast)
  (import (rnrs) (engine value) (engine numeric))

  (define (clamp-int n) (max int64-min (min int64-max n)))

  ;; The longest prefix of s (after leading whitespace) that is a sign and digits, else 0.
  (define (integer-prefix s)
    (let* ([n (string-length s)]
           [start (let loop ([i 0]) (if (and (< i n) (sql-space? (string-ref s i))) (loop (+ i 1)) i))]
           [sign-end (if (and (< start n) (memv (string-ref s start) '(#\+ #\-))) (+ start 1) start)]
           [end (let loop ([i sign-end]) (if (and (< i n) (char<=? #\0 (string-ref s i) #\9)) (loop (+ i 1)) i))])
      (if (= end sign-end)
          0
          (let ([v (string->number (substring s sign-end end))])
            (clamp-int (if (char=? (string-ref s start) #\-) (- v) v))))))

  ;; type is integer, real, text or blob. A BLOB cast to another type acts as its text form (7.9).
  (define (sql-cast v type)
    (cond
      [(sql-null? v) sql-null]
      [(eq? type 'blob) (if (sql-blob? v) v (string->utf8 (text-form v)))]
      [else
       (cast-from-text-or-number (if (sql-blob? v) (bytes->latin1 v) v) type)]))

  (define (cast-from-text-or-number v type)
    (case type
         [(integer) (cond [(string? v) (integer-prefix v)]
                          [(flonum? v) (clamp-int (exact (truncate v)))]
                          [else v])]
         [(real) (inexact (if (string? v) (numeric-prefix v) v))]
         [else (text-form v)])))
