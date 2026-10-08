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

    /** One result column; star is true for '*', otherwise expr and the optional alias are set. */
    record ResultColumn(boolean star, Expr expr, String alias) {}

    /** nullsFirst is null when the statement does not say. */
    record OrderTerm(Expr expr, boolean desc, Boolean nullsFirst) {}

    record Select(List<ResultColumn> columns, String from, Expr where, List<OrderTerm> orderBy,
                  Expr limit, Expr offset) implements Stmt {}
}
