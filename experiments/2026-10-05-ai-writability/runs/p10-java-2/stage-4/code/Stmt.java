import java.util.List;

/** Parsed statements. Names keep the spelling the statement used. */
sealed interface Stmt {
    /** A column as declared; defaultValue is the raw DEFAULT (null = NULL, i.e. none given). */
    record ColumnDef(String name, ColType type, boolean notNull, boolean primaryKey, boolean unique,
                     Object defaultValue) {}

    /** A table-level PRIMARY KEY (primary) or UNIQUE constraint over the named columns. */
    record TableConstraint(boolean primary, List<String> columns) {}

    record CreateTable(String table, boolean ifNotExists, List<ColumnDef> columns,
                       List<TableConstraint> constraints) implements Stmt {}

    record DropTable(String table, boolean ifExists) implements Stmt {}

    record Insert(String table, List<String> columns, List<List<Expr>> rows) implements Stmt {}

    record Assignment(String column, Expr value) {}

    record Update(String table, List<Assignment> sets, Expr where) implements Stmt {}

    record Delete(String table, Expr where) implements Stmt {}

    /**
     * One result column: '*' (star, starTable null), 'q.*' (star, starTable q), or expr with an optional alias.
     */
    record ResultColumn(boolean star, String starTable, Expr expr, String alias) {}

    /** nullsFirst is null when the statement does not say. */
    record OrderTerm(Expr expr, boolean desc, Boolean nullsFirst) {}

    /** One source in FROM: a table with an optional alias, or a parenthesised select with an optional alias. */
    sealed interface FromItem {}

    record TableRef(String table, String alias) implements FromItem {}

    record SubqueryRef(Select select, String alias) implements FromItem {}

    /** CROSS also stands for ',' and a plain JOIN; INNER and LEFT may carry ON or USING (LEFT always does). */
    enum JoinKind { CROSS, INNER, LEFT }

    /** One join after the first source; at most one of on / using is set. */
    record Join(JoinKind kind, FromItem item, Expr on, List<String> using) {}

    record From(FromItem first, List<Join> joins) {}

    record Select(boolean distinct, List<ResultColumn> columns, From from, Expr where, List<Expr> groupBy,
                  Expr having, List<OrderTerm> orderBy, Expr limit, Expr offset) implements Stmt {}
}
