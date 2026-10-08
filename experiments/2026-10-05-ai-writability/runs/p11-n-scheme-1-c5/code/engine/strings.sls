;;; Text operations on already-converted strings: substr, trim, replace, instr (2.4), LIKE (2.3, 7.3) and GLOB (7.2).
(library (engine strings)
  (export text-substr text-trim text-replace text-instr text-like? text-glob?)
  (import (rnrs))

  (define (ascii-fold c) (if (char<=? #\A c #\Z) (integer->char (+ (char->integer c) 32)) c))

  ;; start and len are integers; len is #f when absent. The algorithm is that of 2.4.
  (define (text-substr s start len)
    (let ([L (string-length s)])
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
          (if (or (and q (<= q 0)) (>= p end)) "" (substring s p end))))))

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

  ;; Matching of a text against a compiled pattern: a vector of items, each one of
  ;;   a char (matches itself, ignoring ASCII case when fold? is true), 'one (any one character),
  ;;   'star (any sequence), or (class negated? ranges) with ranges a list of (lo . hi) chars.
  ;; Remembers the last 'star to backtrack to, so matching is linear-ish and never exponential.
  (define (match-items? s items fold?)
    (define n (string-length s))
    (define m (vector-length items))
    (define (norm c) (if fold? (ascii-fold c) c))
    (define (item-matches? item c)
      (cond
        [(char? item) (char=? (norm item) (norm c))]
        [(eq? item 'one) #t]
        [else
         (let ([in? (exists (lambda (r) (and (char<=? (car r) c) (char<=? c (cdr r)))) (caddr item))])
           (if (cadr item) (not in?) in?))]))
    (let loop ([i 0] [j 0] [star-j #f] [star-i 0])
      (cond
        [(< i n)
         (cond
           [(and (< j m) (eq? (vector-ref items j) 'star)) (loop i (+ j 1) (+ j 1) i)]
           [(and (< j m) (item-matches? (vector-ref items j) (string-ref s i)))
            (loop (+ i 1) (+ j 1) star-j star-i)]
           [star-j (loop (+ star-i 1) star-j star-j (+ star-i 1))]
           [else #f])]
        [else
         (let skip ([j j])
           (cond [(= j m) #t]
                 [(eq? (vector-ref items j) 'star) (skip (+ j 1))]
                 [else #f]))])))

  ;; LIKE (2.3, 7.3): % any sequence, _ one character, others match ignoring ASCII case. esc is the
  ;; ESCAPE character or #f; it makes the next pattern character ordinary (even % _ or esc itself),
  ;; checked first so that an esc of % or _ is never a wildcard. A trailing esc matches nothing.
  (define (text-like? s pat esc)
    (let ([m (string-length pat)])
      (let build ([j 0] [acc '()])
        (cond
          [(= j m) (match-items? s (list->vector (reverse acc)) #t)]
          [(and esc (char=? (string-ref pat j) esc))
           (and (< (+ j 1) m) (build (+ j 2) (cons (string-ref pat (+ j 1)) acc)))]
          [(char=? (string-ref pat j) #\%) (build (+ j 1) (cons 'star acc))]
          [(char=? (string-ref pat j) #\_) (build (+ j 1) (cons 'one acc))]
          [else (build (+ j 1) (cons (string-ref pat j) acc))]))))

  ;; The class of a GLOB pattern whose `[` is at index j: (values item next-index), or
  ;; (values #f #f) when no `]` closes it. A `]` right after `[` or `[^` is a member; `-` between two
  ;; members is a range; a first or last `-` is itself (7.2).
  (define (parse-glob-class pat j)
    (let* ([m (string-length pat)]
           [negated (and (< (+ j 1) m) (char=? (string-ref pat (+ j 1)) #\^))]
           [start (if negated (+ j 2) (+ j 1))])
      (let loop ([k start] [ranges '()])
        (cond
          [(>= k m) (values #f #f)]
          [(and (char=? (string-ref pat k) #\]) (> k start))
           (values (list 'class negated ranges) (+ k 1))]
          [(and (< (+ k 2) m) (char=? (string-ref pat (+ k 1)) #\-)
                (not (char=? (string-ref pat (+ k 2)) #\])))
           (loop (+ k 3) (cons (cons (string-ref pat k) (string-ref pat (+ k 2))) ranges))]
          [else
           (let ([c (string-ref pat k)])
             (loop (+ k 1) (cons (cons c c) ranges)))]))))

  ;; GLOB (7.2): * any sequence, ? one character, [...] / [^...] a class; case-sensitive.
  (define (text-glob? s pat)
    (let ([m (string-length pat)])
      (let build ([j 0] [acc '()])
        (if (= j m)
            (match-items? s (list->vector (reverse acc)) #f)
            (let ([c (string-ref pat j)])
              (cond
                [(char=? c #\*) (build (+ j 1) (cons 'star acc))]
                [(char=? c #\?) (build (+ j 1) (cons 'one acc))]
                [(char=? c #\[)
                 (let-values ([(item next) (parse-glob-class pat j)])
                   (and item (build next (cons item acc))))]
                [else (build (+ j 1) (cons c acc))]))))))
  )
