;;; Text operations on already-converted strings: substr, trim, replace, instr (2.4) and LIKE (2.3).
(library (engine strings)
  (export text-substr substr-range text-trim text-replace text-instr bytes-instr text-like?)
  (import (rnrs))

  (define (ascii-fold c) (if (char<=? #\A c #\Z) (integer->char (+ (char->integer c) 32)) c))

  ;; The half-open range [p, end) of substr over L units (2.4); len is #f when absent.
  (define (substr-range L start len)
    (let*-values
        ([(p q) (cond
                  [(< start 0)
                   (let ([p (+ start L)])
                     (if (< p 0)
                         (values 0 (if len (max 0 (+ len p)) #f))
                         (values p len)))]
                  [(> start 0) (values (- start 1) len)]
                  [else (values 0 (and len (if (> len 0) (- len 1) len)))])]
         [(p q) (if (and q (< q 0))
                    (let* ([q (- q)] [p (- p q)])
                      (if (< p 0) (values 0 (+ q p)) (values p q)))
                    (values p q))])
      (let ([end (if q (min L (+ p q)) L)])
        (if (or (and q (<= q 0)) (>= p end)) (values 0 0) (values p end)))))

  ;; start and len are integers; len is #f when absent.
  (define (text-substr s start len)
    (let-values ([(p end) (substr-range (string-length s) start len)])
      (substring s p end)))

  ;; mode is both, left or right; chars is a string of characters to remove.
  (define (text-trim s chars mode)
    (let* ([n (string-length s)]
           [drop? (lambda (c) (exists (lambda (d) (char=? c d)) (string->list chars)))]
           [start (if (eq? mode 'right)
                      0
                      (let loop ([i 0]) (if (and (< i n) (drop? (string-ref s i))) (loop (+ i 1)) i)))]
           [end (if (eq? mode 'left)
                    n
                    (let loop ([e n]) (if (and (> e start) (drop? (string-ref s (- e 1)))) (loop (- e 1)) e)))])
      (substring s start end)))

  ;; Index of the first occurrence of pat in s at or after from, or #f.
  (define (find-text s pat from)
    (let ([n (string-length s)] [m (string-length pat)])
      (let loop ([i from])
        (cond [(> (+ i m) n) #f]
              [(let match ([k 0]) (or (= k m) (and (char=? (string-ref s (+ i k)) (string-ref pat k)) (match (+ k 1)))))
               i]
              [else (loop (+ i 1))]))))

  (define (text-replace s from to)
    (if (string=? from "")
        s
        (let loop ([pos 0] [acc '()])
          (let ([i (find-text s from pos)])
            (if i
                (loop (+ i (string-length from)) (cons to (cons (substring s pos i) acc)))
                (apply string-append (reverse (cons (substring s pos (string-length s)) acc))))))))

  ;; 1-based position of pat in s, or 0.
  (define (text-instr s pat)
    (let ([i (find-text s pat 0)]) (if i (+ i 1) 0)))

  ;; 1-based position of the bytes of pat in bv, or 0.
  (define (bytes-instr bv pat)
    (let ([n (bytevector-length bv)] [m (bytevector-length pat)])
      (let loop ([i 0])
        (cond [(> (+ i m) n) 0]
              [(let match ([k 0]) (or (= k m) (and (= (bytevector-u8-ref bv (+ i k)) (bytevector-u8-ref pat k)) (match (+ k 1)))))
               (+ i 1)]
              [else (loop (+ i 1))]))))

  ;; LIKE: % any sequence, _ one character, others match ignoring ASCII case. Remembers the last
  ;; % to backtrack to, so matching is linear-ish and never exponential.
  (define (text-like? s pat)
    (let ([n (string-length s)] [m (string-length pat)])
      (let loop ([i 0] [j 0] [star-j #f] [star-i 0])
        (cond
          [(< i n)
           (cond
             [(and (< j m) (char=? (string-ref pat j) #\%)) (loop i (+ j 1) (+ j 1) i)]
             [(and (< j m) (or (char=? (string-ref pat j) #\_)
                               (char=? (ascii-fold (string-ref pat j)) (ascii-fold (string-ref s i)))))
              (loop (+ i 1) (+ j 1) star-j star-i)]
             [star-j (loop (+ star-i 1) star-j star-j (+ star-i 1))]
             [else #f])]
          [else
           (let skip ([j j])
             (cond [(= j m) #t]
                   [(char=? (string-ref pat j) #\%) (skip (+ j 1))]
                   [else #f]))])))))
