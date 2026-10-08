import java.util.List;

/** Parsed statements. Names keep the spelling the statement used. */
sealed interface Stmt {
    record ColumnDef(String name, ColType type) {}

    record CreateTable(String table, boolean ifNotExists, List<ColumnDef> columns) implements Stmt {}

    record DropTable(String table, boolean ifExists) implements Stmt {}

    record Insert(String table, List<String> columns, List<List<Expr>> rows) implements Stmt {}

    /** One result column; star is true for '*', otherwise expr and the optional alias are set. */
    record ResultColumn(boolean star, Expr expr, String alias) {}

    /** nullsFirst is null when the statement does not say. */
    record OrderTerm(Expr expr, boolean desc, Boolean nullsFirst) {}

    record Select(List<ResultColumn> columns, String from, Expr where, List<OrderTerm> orderBy,
                  Expr limit, Expr offset) implements Stmt {}
}
