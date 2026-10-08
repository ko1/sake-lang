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
;;;   (call name args distinct? order star?)   order: list of order-term; star?: count(*)
;;;   (case operand whens else)  operand/else: expression or #f; whens: list of (condition . result)
;;;   (between negated? x low high)   (in negated? x items)   (like negated? x pattern)
;;;   (cast x type)             type: integer, real or text
(library (engine ast)
  (export make-create-table-stmt create-table-stmt? create-table-stmt-name
          create-table-stmt-if-not-exists create-table-stmt-columns
          create-table-stmt-constraints
          make-column-def column-def-name column-def-type column-def-not-null column-def-unique
          column-def-primary column-def-default
          make-table-constraint table-constraint-kind table-constraint-columns
          make-update-stmt update-stmt? update-stmt-table update-stmt-assignments update-stmt-where
          make-delete-stmt delete-stmt? delete-stmt-table delete-stmt-where
          make-drop-table-stmt drop-table-stmt? drop-table-stmt-name drop-table-stmt-if-exists
          make-insert-stmt insert-stmt? insert-stmt-table insert-stmt-columns insert-stmt-rows
          make-select-stmt select-stmt? select-stmt-items select-stmt-from select-stmt-where
          select-stmt-distinct select-stmt-group-by select-stmt-having
          select-stmt-order-by select-stmt-limit select-stmt-offset
          make-select-item select-item-expr select-item-alias
          make-order-term order-term-expr order-term-direction order-term-nulls)
  (import (rnrs))

  ;; columns: list of column-def; constraints: list of table-constraint
  (define-record-type create-table-stmt (fields name if-not-exists columns constraints))
  ;; type: one of the symbols integer real text; not-null/unique/primary: booleans;
  ;; default: a value (NULL when there is no DEFAULT)
  (define-record-type column-def (fields name type not-null unique primary default))
  ;; kind: primary or unique; columns: list of names
  (define-record-type table-constraint (fields kind columns))
  ;; assignments: list of (column-name . expression); where: expression or #f
  (define-record-type update-stmt (fields table assignments where))
  (define-record-type delete-stmt (fields table where))
  (define-record-type drop-table-stmt (fields name if-exists))
  ;; columns: list of names or #f; rows: list of lists of expressions
  (define-record-type insert-stmt (fields table columns rows))
  ;; items: list of the symbol star or select-item; from: table name or #f; distinct: boolean;
  ;; where/having/limit/offset: expression or #f; group-by, order-by: lists of expressions / order-term
  (define-record-type select-stmt (fields items distinct from where group-by having order-by limit offset))
  (define-record-type select-item (fields expr alias))
  ;; direction: asc or desc; nulls: first, last or #f
  (define-record-type order-term (fields expr direction nulls)))
