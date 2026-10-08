;;; The syntax tree produced by the parser and read by the executor.
;;;
;;; Names are `name` records (text as written, lowercase key). Expressions are tagged lists:
;;;   (lit value) (col name) (neg e) (pos e) (not e) (binop op l r)
;;;   (call name args distinct? order star?)  -- order: list of order-term; star?: `count(*)`
;;;   (case operand-or-#f ((condition . result) ...) else-or-#f)
;;;   (between x low high negated?) (in x (e ...) negated?) (like x pattern negated?) (cast x type)
;;; where op is one of plus minus times divide modulo concat eq ne lt le gt ge is isnot and or.
;;; Column types are the symbols integer, real, text.
(library (engine ast)
  (export make-name name? name-text name-lower
          make-column-def column-def? column-def-name column-def-type column-def-not-null?
          column-def-primary-key? column-def-unique? column-def-default
          make-table-constraint table-constraint? table-constraint-kind table-constraint-columns
          make-create-table create-table? create-table-name create-table-if-not-exists
          create-table-columns create-table-constraints
          make-update update? update-table update-assignments update-where
          make-delete delete? delete-table delete-where
          make-drop-table drop-table? drop-table-name drop-table-if-exists
          make-insert insert? insert-table insert-columns insert-rows
          make-select-stmt select-stmt? select-stmt-distinct? select-stmt-items select-stmt-from
          select-stmt-where select-stmt-group select-stmt-having select-stmt-order select-stmt-limit select-stmt-offset
          make-result-column result-column-expr result-column-alias
          make-order-term order-term-expr order-term-descending? order-term-nulls)
  (import (rnrs))

  (define-record-type name (fields text lower))
  ;; default: #f or (list value) (the literal after DEFAULT, possibly NULL).
  (define-record-type column-def (fields name type not-null? primary-key? unique? default))
  ;; kind is primary-key or unique; columns is a list of names.
  (define-record-type table-constraint (fields kind columns))

  (define-record-type create-table (fields name if-not-exists columns constraints))
  ;; assignments: list of (name . expression); where: #f or an expression.
  (define-record-type update (fields table assignments where))
  (define-record-type delete (fields table where))
  (define-record-type drop-table (fields name if-exists))
  ;; columns: #f or a list of names; rows: a list of lists of expressions.
  (define-record-type insert (fields table columns rows))

  ;; distinct?: SELECT DISTINCT. from: #f or a name; where, having, limit, offset: #f or an
  ;; expression; group: list of expressions; order: list of order-term.
  (define-record-type select-stmt
    (fields distinct? items from where group having order limit offset))
  ;; expr is the symbol star for `*`; alias is #f or a name.
  (define-record-type result-column (fields expr alias))
  ;; nulls is first, last or #f (default).
  (define-record-type order-term (fields expr descending? nulls)))
