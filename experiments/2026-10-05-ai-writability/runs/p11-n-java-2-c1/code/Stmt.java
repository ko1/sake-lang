import java.util.List;

/** Parsed statements. Names keep the spelling the statement used. */
sealed interface Stmt {
    /**
     * A column as declared; defaultValue is the raw DEFAULT (null = NULL, i.e. none given); collation is
     * its COLLATE (BINARY when none).
     */
    record ColumnDef(String name, ColType type, boolean notNull, boolean primaryKey, boolean unique,
                     Object defaultValue, Collation collation) {}

    /** A table-level PRIMARY KEY (primary) or UNIQUE constraint over the named columns. */
    record TableConstraint(boolean primary, List<String> columns) {}

    record CreateTable(String table, boolean ifNotExists, List<ColumnDef> columns,
                       List<TableConstraint> constraints) implements Stmt {}

    record DropTable(String table, boolean ifExists) implements Stmt {}

    /** Rows come from VALUES (rows) or from a select (select); WITH may have started the statement (with). */
    record Insert(String table, List<String> columns, List<List<Expr>> rows, Select select, With with)
        implements Stmt {}

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

    enum BoundKind { UNBOUNDED_PRECEDING, PRECEDING, CURRENT_ROW, FOLLOWING, UNBOUNDED_FOLLOWING }

    /** One end of a window frame; offset (a Long or Double literal) is set for PRECEDING / FOLLOWING only. */
    record Bound(BoundKind kind, Object offset) {}

    /** ROWS or RANGE frame (rows true for ROWS); a bare start has end CURRENT ROW. */
    record Frame(boolean rows, Bound start, Bound end) {}

    /** Window-spec as written: base names a WINDOW-clause window (or null); frame is null when absent. */
    record WindowSpec(String base, List<Expr> partition, List<OrderTerm> order, Frame frame) {}

    /** One entry of a WINDOW clause. */
    record NamedWindow(String name, WindowSpec spec) {}

    /** One simple SELECT, without ORDER BY / LIMIT. */
    record Core(boolean distinct, List<ResultColumn> columns, From from, Expr where, List<Expr> groupBy,
                Expr having, List<NamedWindow> windows) {}

    enum CompoundOp {
        UNION("UNION"), UNION_ALL("UNION ALL"), INTERSECT("INTERSECT"), EXCEPT("EXCEPT");

        /** The operator as written in SQL (used in error messages). */
        final String sql;

        CompoundOp(String sql) {
            this.sql = sql;
        }
    }

    /** A simple select joined to the ones before it by op. */
    record CompoundPart(CompoundOp op, Core select) {}

    /** name [(columns)] AS (select); columns is null when absent. */
    record Cte(String name, List<String> columns, Select select) {}

    /** WITH [RECURSIVE] ctes. */
    record With(boolean recursive, List<Cte> ctes) {}

    /**
     * A full select: first, then the compound parts left to right (none for a plain select); the trailing
     * ORDER BY / LIMIT / OFFSET apply to the whole. with is null when absent.
     */
    record Select(With with, Core first, List<CompoundPart> rest, List<OrderTerm> orderBy, Expr limit,
                  Expr offset) implements Stmt {}

    /** CREATE VIEW: columns is null without a column list. */
    record CreateView(String name, boolean ifNotExists, List<String> columns, Select select) implements Stmt {}

    record DropView(String name, boolean ifExists) implements Stmt {}

    /** collations.get(i) is the COLLATE name written on column i of the index, or null. */
    record CreateIndex(String name, boolean unique, boolean ifNotExists, String table, List<String> columns,
                       List<String> collations) implements Stmt {}

    record DropIndex(String name, boolean ifExists) implements Stmt {}

    record AlterAddColumn(String table, ColumnDef column) implements Stmt {}

    record AlterRenameTable(String table, String newName) implements Stmt {}

    record AlterRenameColumn(String table, String column, String newName) implements Stmt {}

    record Begin() implements Stmt {}

    record Commit() implements Stmt {}

    record Rollback() implements Stmt {}
}
