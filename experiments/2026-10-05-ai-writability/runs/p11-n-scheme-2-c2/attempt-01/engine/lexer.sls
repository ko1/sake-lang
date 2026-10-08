;;; (engine lexer) -- splitting a script into statements, and a statement into tokens.
;;;
;;; Token kinds and values:
;;;   int / real   number
;;;   string       the text, quotes removed
;;;   blob         a bytevector
;;;   ident        value = the name as written (quotes removed), lname = lower-cased
;;;   keyword      value = lower-case symbol, e.g. 'select
;;;   op           value = symbol: + - * / % concat = != < <= > >= lparen rparen comma dot
;;; Anything the lexer cannot read is a syntax error.
(library (engine lexer)
  (export split-statements tokenize token-kind token-value token-lname)
  (import (rnrs) (engine errors) (engine values))

  (define-record-type token (fields kind value lname))

  (define keywords
    (let ([table (make-hashtable string-hash string=?)])
      (for-each (lambda (word) (hashtable-set! table word (string->symbol word)))
                '("add" "all" "alter" "and" "as" "asc" "begin" "between" "by" "case" "cast"
                  "column" "commit" "create" "cross" "current" "default" "delete" "desc"
                  "distinct" "drop" "else" "end" "except" "exists" "first" "following" "from"
                  "group" "having" "if" "in" "index" "inner" "insert" "intersect" "into" "is"
                  "join" "key" "last" "left" "like" "limit" "not" "null" "nulls" "offset" "on"
                  "or" "order" "outer" "over" "partition" "preceding" "primary" "range"
                  "recursive" "rename" "rollback" "row" "rows" "select" "set" "table" "then"
                  "to" "transaction" "unbounded" "union" "unique" "update" "using" "values"
                  "view" "when" "where" "window" "with"))
      table))

  (define (char-at s i) (if (< i (string-length s)) (string-ref s i) #\nul))
  (define (letter? c) (or (and (char>=? c #\a) (char<=? c #\z)) (and (char>=? c #\A) (char<=? c #\Z))))
  (define (ident-start? c) (or (letter? c) (char=? c #\_)))
  (define (ident-char? c) (or (ident-start? c) (digit-char? c)))

  (define (syntax-error) (raise-sql-error "syntax error"))

  ;; (values blob next-index) of the blob literal X'..' whose X is at i: an even number of
  ;; hexadecimal digits up to the next quote, else a syntax error.
  (define (read-blob s i)
    (let* ([start (+ i 2)]
           [end (let loop ([j start])
                  (cond [(>= j (string-length s)) (syntax-error)]
                        [(char=? (string-ref s j) #\') j]
                        [else (loop (+ j 1))]))]
           [digits (map (lambda (c) (or (hex-digit-value c) (syntax-error)))
                        (string->list (substring s start end)))])
      (when (odd? (length digits)) (syntax-error))
      (values (u8-list->bytevector
               (let pairs ([ds digits])
                 (if (null? ds) '() (cons (+ (* 16 (car ds)) (cadr ds)) (pairs (cddr ds))))))
              (+ end 1))))

  ;;; ---- skipping and quoted text ------------------------------------------

  ;; Index just after the line comment starting at i.
  (define (skip-line-comment s i)
    (let loop ([i i])
      (cond [(>= i (string-length s)) i]
            [(char=? (string-ref s i) #\newline) (+ i 1)]
            [else (loop (+ i 1))])))

  ;; Index just after the block comment starting at i (end of text if unterminated).
  (define (skip-block-comment s i)
    (let loop ([i (+ i 2)])
      (cond [(>= i (string-length s)) i]
            [(and (char=? (string-ref s i) #\*) (char=? (char-at s (+ i 1)) #\/)) (+ i 2)]
            [else (loop (+ i 1))])))

  (define (line-comment-at? s i) (and (char=? (char-at s i) #\-) (char=? (char-at s (+ i 1)) #\-)))
  (define (block-comment-at? s i) (and (char=? (char-at s i) #\/) (char=? (char-at s (+ i 1)) #\*)))

  ;; Index just after the quoted text starting at i, or the text length if unterminated.
  (define (skip-quoted s i)
    (let ([q (string-ref s i)] [n (string-length s)])
      (let loop ([i (+ i 1)])
        (cond [(>= i n) n]
              [(char=? (string-ref s i) q)
               (if (char=? (char-at s (+ i 1)) q) (loop (+ i 2)) (+ i 1))]
              [else (loop (+ i 1))]))))

  ;; (values contents next-index) of the quoted text at i; "" is one quote char.
  (define (read-quoted s i)
    (let ([q (string-ref s i)] [n (string-length s)])
      (let loop ([i (+ i 1)] [acc '()])
        (cond [(>= i n) (syntax-error)]
              [(char=? (string-ref s i) q)
               (if (char=? (char-at s (+ i 1)) q)
                   (loop (+ i 2) (cons q acc))
                   (values (list->string (reverse acc)) (+ i 1)))]
              [else (loop (+ i 1) (cons (string-ref s i) acc))]))))

  ;;; ---- statements ----------------------------------------------------------

  ;; The text of each statement (without its ';'), found by scanning for ';'
  ;; outside literals, quoted identifiers and comments.  A final piece with no
  ;; ';' is returned too (it is an error unless it is blank).
  (define (split-statements text)
    (let ([n (string-length text)])
      (let loop ([i 0] [start 0] [acc '()])
        (cond
          [(>= i n) (reverse (if (< start n) (cons (substring text start n) acc) acc))]
          [else
           (let ([c (string-ref text i)])
             (cond [(or (char=? c #\') (char=? c #\")) (loop (skip-quoted text i) start acc)]
                   [(line-comment-at? text i) (loop (skip-line-comment text i) start acc)]
                   [(block-comment-at? text i) (loop (skip-block-comment text i) start acc)]
                   [(char=? c #\;) (loop (+ i 1) (+ i 1) (cons (substring text start i) acc))]
                   [else (loop (+ i 1) start acc)]))]))))

  ;;; ---- tokens --------------------------------------------------------------

  (define (word-token word)
    (let* ([lname (ascii-downcase word)] [kw (hashtable-ref keywords lname #f)])
      (if kw (make-token 'keyword kw lname) (make-token 'ident word lname))))

  (define (scan-while s i pred)
    (let loop ([i i]) (if (and (< i (string-length s)) (pred (string-ref s i))) (loop (+ i 1)) i)))

  ;; (values op-symbol next-index)
  (define (read-operator s i)
    (let ([c (string-ref s i)] [c2 (char-at s (+ i 1))])
      (define (two sym) (values sym (+ i 2)))
      (define (one sym) (values sym (+ i 1)))
      (case c
        [(#\|) (if (char=? c2 #\|) (two 'concat) (syntax-error))]
        [(#\=) (if (char=? c2 #\=) (two '=) (one '=))]
        [(#\!) (if (char=? c2 #\=) (two '!=) (syntax-error))]
        [(#\<) (cond [(char=? c2 #\=) (two '<=)] [(char=? c2 #\>) (two '!=)] [else (one '<)])]
        [(#\>) (if (char=? c2 #\=) (two '>=) (one '>))]
        [(#\+) (one '+)] [(#\-) (one '-)] [(#\*) (one '*)] [(#\/) (one '/)] [(#\%) (one '%)]
        [(#\() (one 'lparen)] [(#\)) (one 'rparen)] [(#\,) (one 'comma)] [(#\.) (one 'dot)]
        [else (syntax-error)])))

  ;; The tokens of one statement's text, as a list.
  (define (tokenize text)
    (let ([n (string-length text)])
      (let loop ([i 0] [acc '()])
        (if (>= i n)
            (reverse acc)
            (let ([c (string-ref text i)])
              (cond
                [(whitespace-char? c) (loop (+ i 1) acc)]
                [(line-comment-at? text i) (loop (skip-line-comment text i) acc)]
                [(block-comment-at? text i) (loop (skip-block-comment text i) acc)]
                [(and (or (char=? c #\X) (char=? c #\x)) (char=? (char-at text (+ i 1)) #\'))
                 (let-values ([(blob j) (read-blob text i)])
                   (loop j (cons (make-token 'blob blob #f) acc)))]
                [(ident-start? c)
                 (let ([j (scan-while text i ident-char?)])
                   (loop j (cons (word-token (substring text i j)) acc)))]
                [(or (digit-char? c) (and (char=? c #\.) (digit-char? (char-at text (+ i 1)))))
                 (let-values ([(num j) (scan-numeric text i)])
                   (when (ident-char? (char-at text j)) (syntax-error))
                   (loop j (cons (make-token (if (integer-value? num) 'int 'real) num #f) acc)))]
                [(char=? c #\')
                 (let-values ([(str j) (read-quoted text i)])
                   (loop j (cons (make-token 'string str #f) acc)))]
                [(char=? c #\")
                 (let-values ([(name j) (read-quoted text i)])
                   (loop j (cons (make-token 'ident name (ascii-downcase name)) acc)))]
                [else
                 (let-values ([(op j) (read-operator text i)])
                   (loop j (cons (make-token 'op op #f) acc)))])))))))
