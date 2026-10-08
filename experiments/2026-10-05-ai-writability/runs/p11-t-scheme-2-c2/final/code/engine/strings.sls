;;; (engine strings) -- text algorithms behind LIKE and the text functions
;;; (spec 2.3, 2.4).  They work on Scheme strings; the callers pass text forms.
(library (engine strings)
  (export substr-text trim-text replace-text find-substring like-match?)
  (import (rnrs) (engine values))

  ;;; ---- substr (2.4) ----------------------------------------------------

  ;; start and len are exact integers; len #f means "to the end".
  (define (substr-text s start len)
    (let ([L (string-length s)])
      (let*-values ([(p q) (substr-adjust-start L start (or len (expt 2 62)))]
                    [(p q) (substr-adjust-backwards p q)])
        (if (<= q 0)
            ""
            (substring s (min p L) (min L (+ p q)))))))

  ;; Step 1 of the spec: positions count from 1, negative start from the end.
  (define (substr-adjust-start L p q)
    (cond [(< p 0) (let ([p (+ p L)])
                     (if (< p 0) (values 0 (max 0 (+ q p))) (values p q)))]
          [(> p 0) (values (- p 1) q)]
          [else (values 0 (if (> q 0) (- q 1) q))]))

  ;; Step 2: a negative length takes the characters before the start.
  (define (substr-adjust-backwards p q)
    (if (< q 0)
        (let ([p (- p (- q))] [q (- q)])
          (if (< p 0) (values 0 (+ q p)) (values p q)))
        (values p q)))

  ;;; ---- trim, replace, instr ------------------------------------------------

  ;; Remove characters found in `chars` from the left and/or right of s.
  (define (trim-text s chars left? right?)
    (let* ([in-set? (lambda (c) (exists (lambda (d) (char=? c d)) (string->list chars)))]
           [n (string-length s)]
           [start (if left?
                      (let loop ([i 0]) (if (and (< i n) (in-set? (string-ref s i))) (loop (+ i 1)) i))
                      0)]
           [end (if right?
                    (let loop ([i n]) (if (and (> i start) (in-set? (string-ref s (- i 1)))) (loop (- i 1)) i))
                    n)])
      (substring s start end)))

  ;; 0-based index of the first occurrence of needle in hay at or after `from`, or #f.
  (define (find-substring hay needle from)
    (let ([n (string-length hay)] [m (string-length needle)])
      (let loop ([i from])
        (cond [(> (+ i m) n) #f]
              [(string=? (substring hay i (+ i m)) needle) i]
              [else (loop (+ i 1))]))))

  (define (replace-text s from to)
    (if (string=? from "")
        s
        (let loop ([start 0] [acc '()])
          (let ([i (find-substring s from start)])
            (if i
                (loop (+ i (string-length from)) (cons to (cons (substring s start i) acc)))
                (apply string-append (reverse (cons (substring s start (string-length s)) acc))))))))

  ;;; ---- LIKE (2.3) -----------------------------------------------------------

  (define (fold-case c)
    (if (and (char>=? c #\A) (char<=? c #\Z)) (integer->char (+ (char->integer c) 32)) c))

  ;; Does pattern p (% = any run, _ = one character, case-insensitive) match all of s?
  ;; Greedy matching that remembers the last % to retry from.
  (define (like-match? s p)
    (let ([n (string-length s)] [m (string-length p)])
      (let loop ([i 0] [j 0] [star-j #f] [star-i 0])
        (define (backtrack)
          (and star-j (loop (+ star-i 1) star-j star-j (+ star-i 1))))
        (cond
          [(< i n)
           (let ([pc (and (< j m) (string-ref p j))])
             (cond [(and pc (char=? pc #\%)) (loop i (+ j 1) (+ j 1) i)]
                   [(and pc (or (char=? pc #\_) (char=? (fold-case pc) (fold-case (string-ref s i)))))
                    (loop (+ i 1) (+ j 1) star-j star-i)]
                   [else (backtrack)]))]
          [else
           (let skip ([j j])
             (cond [(= j m) #t]
                   [(char=? (string-ref p j) #\%) (skip (+ j 1))]
                   [else #f]))])))))
