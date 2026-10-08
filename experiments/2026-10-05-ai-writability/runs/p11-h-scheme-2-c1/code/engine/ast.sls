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
;;;   (collate x name)          x COLLATE name; name as written (checked when compiled)
;;;   (subquery select)  (in-select negated? x select)  (exists select)   select: a select-stmt
;;;   (window-call name args star? over)   f(...) OVER ...; over: a window name (string) or
;;;                             (window base partition order frame): base a name or #f, partition a list
;;;                             of expressions, order a list of order-term, frame #f or (mode start end)
;;;                             with mode rows or range, bound (unbounded-preceding) (preceding n)
;;;                             (current) (following n) (unbounded-following)
;;;   (slot index)              internal: the column at an absolute FROM index (from a * expansion)
(library (engine ast)
  (export make-create-table-stmt create-table-stmt? create-table-stmt-name
          create-table-stmt-if-not-exists create-table-stmt-columns
          create-table-stmt-constraints
          make-column-def column-def-name column-def-type column-def-not-null column-def-unique
          column-def-primary column-def-default column-def-collation
          make-table-constraint table-constraint-kind table-constraint-columns
          make-update-stmt update-stmt? update-stmt-table update-stmt-assignments update-stmt-where
          make-delete-stmt delete-stmt? delete-stmt-table delete-stmt-where
          make-drop-table-stmt drop-table-stmt? drop-table-stmt-name drop-table-stmt-if-exists
          make-insert-stmt insert-stmt? insert-stmt-table insert-stmt-columns insert-stmt-rows
          insert-stmt-query
          make-select-stmt select-stmt? select-stmt-items select-stmt-from select-stmt-where
          select-stmt-distinct select-stmt-group-by select-stmt-having
          select-stmt-order-by select-stmt-limit select-stmt-offset select-stmt-with select-stmt-windows
          make-compound-stmt compound-stmt? compound-stmt-first compound-stmt-rest
          compound-stmt-order-by compound-stmt-limit compound-stmt-offset compound-stmt-with
          query? query-with query-attach-with
          make-with-clause with-clause-recursive with-clause-ctes
          make-cte cte-name cte-columns cte-select
          make-create-view-stmt create-view-stmt? create-view-stmt-name create-view-stmt-if-not-exists
          create-view-stmt-columns create-view-stmt-select
          make-drop-view-stmt drop-view-stmt? drop-view-stmt-name drop-view-stmt-if-exists
          make-create-index-stmt create-index-stmt? create-index-stmt-name create-index-stmt-unique
          create-index-stmt-if-not-exists create-index-stmt-table create-index-stmt-columns
          create-index-stmt-collations
          make-drop-index-stmt drop-index-stmt? drop-index-stmt-name drop-index-stmt-if-exists
          make-alter-add-column-stmt alter-add-column-stmt? alter-add-column-stmt-table
          alter-add-column-stmt-column
          make-alter-rename-table-stmt alter-rename-table-stmt? alter-rename-table-stmt-table
          alter-rename-table-stmt-new-name
          make-alter-rename-column-stmt alter-rename-column-stmt? alter-rename-column-stmt-table
          alter-rename-column-stmt-column alter-rename-column-stmt-new-name
          make-transaction-stmt transaction-stmt? transaction-stmt-action
          make-select-item select-item-expr select-item-alias
          make-order-term order-term-expr order-term-direction order-term-nulls
          make-from-clause from-clause-first from-clause-joins
          make-join-clause join-clause-kind join-clause-item join-clause-constraint
          make-table-ref table-ref? table-ref-name table-ref-alias
          make-subquery-ref subquery-ref-select subquery-ref-alias
          make-qualified-star qualified-star? qualified-star-qualifier)
  (import (rnrs))

  ;; columns: list of column-def; constraints: list of table-constraint
  (define-record-type create-table-stmt (fields name if-not-exists columns constraints))
  ;; type: one of the symbols integer real text; not-null/unique/primary: booleans;
  ;; default: a value (NULL when there is no DEFAULT); collation: a collation name as written, or #f
  (define-record-type column-def (fields name type not-null unique primary default collation))
  ;; kind: primary or unique; columns: list of names
  (define-record-type table-constraint (fields kind columns))
  ;; assignments: list of (column-name . expression); where: expression or #f
  (define-record-type update-stmt (fields table assignments where))
  (define-record-type delete-stmt (fields table where))
  (define-record-type drop-table-stmt (fields name if-exists))
  ;; columns: list of names or #f; the source is either rows (a list of lists of expressions)
  ;; or query (a select or compound; rows is then #f)
  (define-record-type insert-stmt (fields table columns rows query))
  ;; items: list of the symbol star, qualified-star or select-item; from: from-clause or #f; distinct: boolean;
  ;; where/having/limit/offset: expression or #f; group-by, order-by: lists of expressions / order-term
  ;; with: a with-clause or #f.  Inside a compound select the order-by/limit/offset are empty.
  ;; windows: the WINDOW clause, a list of (name . window-spec) with window-spec as in `window-call`.
  (define-record-type select-stmt
    (fields items distinct from where group-by having order-by limit offset with windows))
  ;; A compound select: first and the cdr of each rest entry are select-stmt; rest is a list of
  ;; (op . select-stmt), op one of union union-all intersect except.  order-by: list of order-term.
  (define-record-type compound-stmt (fields first rest order-by limit offset with))
  ;; recursive: boolean; ctes: list of cte, in order
  (define-record-type with-clause (fields recursive ctes))
  ;; columns: list of names or #f; select: a select-stmt or compound-stmt
  (define-record-type cte (fields name columns select))

  (define (query? x) (or (select-stmt? x) (compound-stmt? x)))
  (define (query-with q) (if (select-stmt? q) (select-stmt-with q) (compound-stmt-with q)))
  ;; The same query with a WITH clause put on it.
  (define (query-attach-with q with)
    (if (select-stmt? q)
        (make-select-stmt (select-stmt-items q) (select-stmt-distinct q) (select-stmt-from q)
                          (select-stmt-where q) (select-stmt-group-by q) (select-stmt-having q)
                          (select-stmt-order-by q) (select-stmt-limit q) (select-stmt-offset q) with
                          (select-stmt-windows q))
        (make-compound-stmt (compound-stmt-first q) (compound-stmt-rest q) (compound-stmt-order-by q)
                            (compound-stmt-limit q) (compound-stmt-offset q) with)))

  ;; columns: list of names or #f
  (define-record-type create-view-stmt (fields name if-not-exists columns select))
  (define-record-type drop-view-stmt (fields name if-exists))
  ;; collations: one per column, a collation name as written or #f
  (define-record-type create-index-stmt (fields name unique if-not-exists table columns collations))
  (define-record-type drop-index-stmt (fields name if-exists))
  ;; column: a column-def
  (define-record-type alter-add-column-stmt (fields table column))
  (define-record-type alter-rename-table-stmt (fields table new-name))
  (define-record-type alter-rename-column-stmt (fields table column new-name))
  ;; action: begin, commit or rollback
  (define-record-type transaction-stmt (fields action))
  ;; first: a table-ref or subquery-ref; joins: list of join-clause, joined to the left
  (define-record-type from-clause (fields first joins))
  ;; kind: cross (also `,`), inner or left; item: table-ref or subquery-ref; constraint: #f,
  ;; (on . expression) or (using . column-names)
  (define-record-type join-clause (fields kind item constraint))
  ;; alias: a name or #f
  (define-record-type table-ref (fields name alias))
  (define-record-type subquery-ref (fields select alias))
  (define-record-type qualified-star (fields qualifier))
  (define-record-type select-item (fields expr alias))
  ;; direction: asc or desc; nulls: first, last or #f
  (define-record-type order-term (fields expr direction nulls)))
