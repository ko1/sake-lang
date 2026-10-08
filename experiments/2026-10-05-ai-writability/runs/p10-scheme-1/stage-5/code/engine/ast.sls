;;; The syntax tree produced by the parser and read by the executor.
;;;
;;; Names are `name` records (text as written, lowercase key). Expressions are tagged lists:
;;;   (lit value) (col name) (neg e) (pos e) (not e) (binop op l r)
;;;   (call name args distinct? order star?)  -- order: list of order-term; star?: `count(*)`
;;;   (case operand-or-#f ((condition . result) ...) else-or-#f)
;;;   (between x low high negated?) (in x (e ...) negated?) (like x pattern negated?) (cast x type)
;;;   (qcol qualifier name)              a qualified column reference q.c
;;;   (subquery stmt) (exists stmt) (insub x stmt negated?)   subqueries (4.3)
;;;   (slot index column)                made by the engine, never the parser: a column of the joined row
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
          make-insert insert? insert-table insert-columns insert-source
          make-create-view create-view? create-view-name create-view-if-not-exists
          create-view-columns create-view-query
          make-create-index create-index? create-index-name create-index-unique?
          create-index-if-not-exists create-index-table create-index-columns
          make-drop-view drop-view? drop-view-name drop-view-if-exists
          make-drop-index drop-index? drop-index-name drop-index-if-exists
          make-transaction transaction? transaction-kind
          make-alter-add-column alter-add-column? alter-add-column-table alter-add-column-def
          make-alter-rename-table alter-rename-table? alter-rename-table-table alter-rename-table-new-name
          make-alter-rename-column alter-rename-column? alter-rename-column-table
          alter-rename-column-old alter-rename-column-new
          make-compound compound? compound-first compound-rest compound-order compound-limit compound-offset
          make-with-stmt with-stmt? with-stmt-recursive? with-stmt-ctes with-stmt-body
          make-cte cte? cte-name cte-columns cte-query
          query?
          make-select-stmt select-stmt? select-stmt-distinct? select-stmt-items select-stmt-from
          select-stmt-where select-stmt-group select-stmt-having select-stmt-order select-stmt-limit select-stmt-offset
          make-from-table from-table? from-table-name from-table-alias
          make-from-subquery from-subquery? from-subquery-stmt from-subquery-alias
          make-from-join from-join? from-join-kind from-join-left from-join-right from-join-constraint
          make-result-column result-column-expr result-column-alias
          make-order-term order-term-expr order-term-descending? order-term-nulls)
  (import (rnrs))

  (define-record-type name (fields text lower))
  ;; Anything that produces rows: a select, a compound select or a WITH around either.
  (define (query? x) (or (select-stmt? x) (compound? x) (with-stmt? x)))
  ;; default: #f or (list value) (the literal after DEFAULT, possibly NULL).
  (define-record-type column-def (fields name type not-null? primary-key? unique? default))
  ;; kind is primary-key or unique; columns is a list of names.
  (define-record-type table-constraint (fields kind columns))

  (define-record-type create-table (fields name if-not-exists columns constraints))
  ;; assignments: list of (name . expression); where: #f or an expression.
  (define-record-type update (fields table assignments where))
  (define-record-type delete (fields table where))
  (define-record-type drop-table (fields name if-exists))
  ;; columns: #f or a list of names; source: a list of lists of expressions (VALUES) or a query (5.4).
  (define-record-type insert (fields table columns source))

  ;; columns: #f or a list of names; query: the view's select, kept unchecked until used (5.3).
  (define-record-type create-view (fields name if-not-exists columns query))
  ;; columns: list of names.
  (define-record-type create-index (fields name unique? if-not-exists table columns))
  (define-record-type drop-view (fields name if-exists))
  (define-record-type drop-index (fields name if-exists))
  ;; kind: begin, commit or rollback (5.5).
  (define-record-type transaction (fields kind))
  ;; def: a column-def (5.6).
  (define-record-type alter-add-column (fields table def))
  (define-record-type alter-rename-table (fields table new-name))
  (define-record-type alter-rename-column (fields table old new))

  ;; A compound select (5.1): first is a select-stmt; rest is a list of (op . select-stmt) with op
  ;; one of union, union-all, intersect, except. order/limit/offset are those of the whole result.
  (define-record-type compound (fields first rest order limit offset))
  ;; WITH (5.2): ctes is a list of cte; body is a query, or an insert.
  (define-record-type with-stmt (fields recursive? ctes body))
  ;; columns: #f or a list of names.
  (define-record-type cte (fields name columns query))

;; from-items (4.1). alias: #f or a name. A join associates to the left: left is any from-item,
  ;; right is a from-table or from-subquery. kind: cross, inner or left. constraint: #f,
  ;; (on . expression) or (using . names).
  (define-record-type from-table (fields name alias))
  (define-record-type from-subquery (fields stmt alias))
  (define-record-type from-join (fields kind left right constraint))

  ;; distinct?: SELECT DISTINCT. from: #f or a from-item; where, having, limit, offset: #f or an
  ;; expression; group: list of expressions; order: list of order-term.
  (define-record-type select-stmt
    (fields distinct? items from where group having order limit offset))
    ;; expr is the symbol star for `*`, (qstar name) for `q.*`; alias is #f or a name.
  (define-record-type result-column (fields expr alias))
  ;; nulls is first, last or #f (default).
  (define-record-type order-term (fields expr descending? nulls)))
