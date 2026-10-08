;;; Lexing (1.2): splitting a script into statements, and a statement into tokens.
;;; A token has a kind: kw (value: lowercase symbol), ident (value: lowercase string, text: as
;;; written, unquoted), int / real (value: number), str (value: string), blob (value: bytevector), op (value: string).
(library (engine lexer)
  (export split-statements tokenize token-kind token-text token-value)
  (import (rnrs) (engine errors) (engine numeric))

  (define-record-type token (fields kind text value))

  (define keyword-names
    '("add" "all" "alter" "and" "as" "asc" "begin" "between" "by" "case" "cast" "column" "commit"
      "create" "cross" "current" "default" "delete" "desc" "distinct" "drop" "else" "end" "except"
      "exists" "first" "following" "from" "group" "having" "if" "in" "index" "inner" "insert"
      "intersect" "into" "is" "join" "key" "last" "left" "like" "limit" "not" "null" "nulls"
      "offset" "on" "or" "order" "outer" "over" "partition" "preceding" "primary" "range"
      "recursive" "rename" "rollback" "row" "rows" "select" "set" "table" "then" "to"
      "transaction" "unbounded" "union" "unique" "update" "using" "values" "view" "when" "where"
      "window" "with"))

  (define keywords
    (let ([h (make-hashtable string-hash string=?)])
      (for-each (lambda (k) (hashtable-set! h k (string->symbol k))) keyword-names)
      h))

  (define (ascii-lower s)
    (list->string
     (map (lambda (c) (if (char<=? #\A c #\Z) (integer->char (+ (char->integer c) 32)) c))
          (string->list s))))

  (define (letter? c) (or (char<=? #\a c #\z) (char<=? #\A c #\Z) (char=? c #\_)))
  (define (digit? c) (char<=? #\0 c #\9))
  (define (ident-char? c) (or (letter? c) (digit? c)))

  (define (char-at s i) (and (< i (string-length s)) (string-ref s i)))

  ;; s[i] is the opening quote q. Returns (values content end terminated?); q q stands for one q.
  (define (scan-quoted s i q)
    (let ([n (string-length s)])
      (let loop ([j (+ i 1)] [acc '()])
        (cond [(>= j n) (values (list->string (reverse acc)) n #f)]
              [(char=? (string-ref s j) q)
               (if (eqv? (char-at s (+ j 1)) q)
                   (loop (+ j 2) (cons q acc))
                   (values (list->string (reverse acc)) (+ j 1) #t))]
              [else (loop (+ j 1) (cons (string-ref s j) acc))]))))

  (define (hex-value c)
    (cond [(char<=? #\0 c #\9) (- (char->integer c) 48)]
          [(char<=? #\a c #\f) (- (char->integer c) 87)]
          [(char<=? #\A c #\F) (- (char->integer c) 55)]
          [else #f]))

  ;; The bytes of the hex digits in a blob literal (7.1); an odd count or a non-digit is a syntax error.
  (define (hex->bytes digits)
    (let ([n (string-length digits)])
      (when (odd? n) (raise-syntax-error))
      (let ([bv (make-bytevector (div n 2))])
        (do ([i 0 (+ i 2)]) ((>= i n) bv)
          (let ([hi (hex-value (string-ref digits i))] [lo (hex-value (string-ref digits (+ i 1)))])
            (unless (and hi lo) (raise-syntax-error))
            (bytevector-u8-set! bv (div i 2) (+ (* 16 hi) lo)))))))

  (define (skip-line-comment s i)
    (let loop ([j i])
      (if (or (>= j (string-length s)) (char=? (string-ref s j) #\newline)) j (loop (+ j 1)))))

  ;; s[i..] starts "/*". Returns the index after "*/" (or the end if unterminated).
  (define (skip-block-comment s i)
    (let ([n (string-length s)])
      (let loop ([j (+ i 2)])
        (cond [(>= (+ j 1) n) n]
              [(and (char=? (string-ref s j) #\*) (char=? (string-ref s (+ j 1)) #\/)) (+ j 2)]
              [else (loop (+ j 1))]))))

  (define (comment-start? s i)
    (let ([c (string-ref s i)] [d (char-at s (+ i 1))])
      (cond [(and (char=? c #\-) (eqv? d #\-)) 'line]
            [(and (char=? c #\/) (eqv? d #\*)) 'block]
            [else #f])))

  ;; The statements of a script: the text between `;` that are outside literals and comments.
  ;; A trailing piece after the last `;` is returned too (it normally holds only whitespace).
  (define (split-statements text)
    (let ([n (string-length text)])
      (let loop ([i 0] [start 0] [acc '()])
        (cond
          [(>= i n) (reverse (cons (substring text start n) acc))]
          [else
           (let ([c (string-ref text i)])
             (cond
               [(char=? c #\;) (loop (+ i 1) (+ i 1) (cons (substring text start i) acc))]
               [(or (char=? c #\') (char=? c #\"))
                (let-values ([(content end ok) (scan-quoted text i c)]) (loop end start acc))]
               [(comment-start? text i)
                => (lambda (kind)
                     (loop (if (eq? kind 'line) (skip-line-comment text i) (skip-block-comment text i))
                           start acc))]
               [else (loop (+ i 1) start acc)]))]))))

  (define operators-2 '("||" "==" "!=" "<>" "<=" ">="))
  (define operators-1 "+-*/%=<>(),.")

  ;; The tokens of one statement. Anything the lexical rules do not allow is a syntax error.
  (define (tokenize s)
    (let ([n (string-length s)])
      (let loop ([i 0] [acc '()])
        (if (>= i n)
            (reverse acc)
            (let ([c (string-ref s i)])
              (cond
                [(sql-space? c) (loop (+ i 1) acc)]
                [(comment-start? s i)
                 => (lambda (kind)
                      (loop (if (eq? kind 'line) (skip-line-comment s i) (skip-block-comment s i))
                            acc))]
                [(and (memv c '(#\x #\X)) (eqv? (char-at s (+ i 1)) #\'))
                 (let-values ([(content end ok) (scan-quoted s (+ i 1) #\')])
                   (unless ok (raise-syntax-error))
                   (loop end (cons (make-token 'blob (substring s i end) (hex->bytes content)) acc)))]
                [(letter? c)
                 (let* ([end (let scan ([j i]) (if (and (< j n) (ident-char? (string-ref s j))) (scan (+ j 1)) j))]
                        [word (substring s i end)]
                        [lower (ascii-lower word)]
                        [kw (hashtable-ref keywords lower #f)])
                   (loop end (cons (if kw (make-token 'kw word kw) (make-token 'ident word lower)) acc)))]
                [(char=? c #\")
                 (let-values ([(content end ok) (scan-quoted s i #\")])
                   (unless ok (raise-syntax-error))
                   (loop end (cons (make-token 'ident content (ascii-lower content)) acc)))]
                [(char=? c #\')
                 (let-values ([(content end ok) (scan-quoted s i #\')])
                   (unless ok (raise-syntax-error))
                   (loop end (cons (make-token 'str content content) acc)))]
                [(or (digit? c) (and (char=? c #\.) (let ([d (char-at s (+ i 1))]) (and d (digit? d)))))
                 (let-values ([(num end) (scan-number s i)])
                   (let ([d (char-at s end)])
                     (when (and d (ident-char? d)) (raise-syntax-error)))
                   (loop end (cons (make-token (if (flonum? num) 'real 'int) (substring s i end) num) acc)))]
                [else
                 (let ([two (and (< (+ i 1) n) (substring s i (+ i 2)))])
                   (cond
                     [(and two (member two operators-2))
                      (loop (+ i 2) (cons (make-token 'op two two) acc))]
                     [(let scan ([k 0]) (and (< k (string-length operators-1))
                                             (or (char=? c (string-ref operators-1 k)) (scan (+ k 1)))))
                      (let ([o (string c)]) (loop (+ i 1) (cons (make-token 'op o o) acc)))]
                     [else (raise-syntax-error)]))])))))))
