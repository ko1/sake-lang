;;; (engine ast) -- the shapes the parser produces and the executors consume.
;;;
;;; Statements are the records below.  Names are strings *as written* (quotes
;;; removed); compare them with ascii-downcase.
;;;
;;; Expressions are tagged lists:
;;;   (lit value)               a constant (NULL is the symbol null)
;;;   (col qualifier name)      qualifier is a string or #f
;;;   (neg e) (pos e) (not e)
;;;   (bin op l r)              op: + - * / % concat = != < <= > >= is is-not and or
;;;   (call name args)
(library (engine ast)
  (export make-create-table-stmt create-table-stmt? create-table-stmt-name
          create-table-stmt-if-not-exists create-table-stmt-columns
          make-drop-table-stmt drop-table-stmt? drop-table-stmt-name drop-table-stmt-if-exists
          make-insert-stmt insert-stmt? insert-stmt-table insert-stmt-columns insert-stmt-rows
          make-select-stmt select-stmt? select-stmt-items select-stmt-from select-stmt-where
          select-stmt-order-by select-stmt-limit select-stmt-offset
          make-select-item select-item-expr select-item-alias
          make-order-term order-term-expr order-term-direction order-term-nulls)
  (import (rnrs))

  ;; columns: list of (name . type) with type one of the symbols integer real text
  (define-record-type create-table-stmt (fields name if-not-exists columns))
  (define-record-type drop-table-stmt (fields name if-exists))
  ;; columns: list of names or #f; rows: list of lists of expressions
  (define-record-type insert-stmt (fields table columns rows))
  ;; items: list of the symbol star or select-item; from: table name or #f;
  ;; where/limit/offset: expression or #f; order-by: list of order-term
  (define-record-type select-stmt (fields items from where order-by limit offset))
  (define-record-type select-item (fields expr alias))
  ;; direction: asc or desc; nulls: first, last or #f
  (define-record-type order-term (fields expr direction nulls)))
