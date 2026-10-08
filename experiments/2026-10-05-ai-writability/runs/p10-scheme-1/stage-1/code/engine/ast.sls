;;; The syntax tree produced by the parser and read by the executor.
;;;
;;; Names are `name` records (text as written, lowercase key). Expressions are tagged lists:
;;;   (lit value) (col name) (neg e) (pos e) (not e) (binop op l r) (call name args)
;;; where op is one of plus minus times divide modulo concat eq ne lt le gt ge is isnot and or.
;;; Column types are the symbols integer, real, text.
(library (engine ast)
  (export make-name name-text name-lower
          make-column-def column-def-name column-def-type
          make-create-table create-table? create-table-name create-table-if-not-exists create-table-columns
          make-drop-table drop-table? drop-table-name drop-table-if-exists
          make-insert insert? insert-table insert-columns insert-rows
          make-select-stmt select-stmt? select-stmt-items select-stmt-from select-stmt-where
          select-stmt-order select-stmt-limit select-stmt-offset
          make-result-column result-column-expr result-column-alias
          make-order-term order-term-expr order-term-descending? order-term-nulls)
  (import (rnrs))

  (define-record-type name (fields text lower))
  (define-record-type column-def (fields name type))

  (define-record-type create-table (fields name if-not-exists columns))
  (define-record-type drop-table (fields name if-exists))
  ;; columns: #f or a list of names; rows: a list of lists of expressions.
  (define-record-type insert (fields table columns rows))

  ;; from: #f or a name; where, limit, offset: #f or an expression; order: list of order-term.
  (define-record-type select-stmt (fields items from where order limit offset))
  ;; expr is the symbol star for `*`; alias is #f or a name.
  (define-record-type result-column (fields expr alias))
  ;; nulls is first, last or #f (default).
  (define-record-type order-term (fields expr descending? nulls)))
