package sqlengine.exec;

import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.Expr;

/**
 * What names and aggregate calls mean while binding: the table's columns, plus (where allowed)
 * result-column aliases keyed by normalised name (an alias stands for its expression), and what an
 * aggregate call does here (see Aggregates.Context).
 */
record Scope(List<Column> columns, Map<String, Expr> aliases, Aggregates.Context agg) {
    /** A scope in which an aggregate call is misuse (WHERE, UPDATE, DELETE, VALUES, LIMIT). */
    Scope(List<Column> columns, Map<String, Expr> aliases) {
        this(columns, aliases, Aggregates.MISUSE);
    }

    Scope withAliases(Map<String, Expr> a) {
        return new Scope(columns, a, agg);
    }

    Scope withAgg(Aggregates.Context c) {
        return new Scope(columns, aliases, c);
    }
}
