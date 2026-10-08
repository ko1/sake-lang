package sqlengine.exec;

import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.Expr;

/**
 * What names and aggregate calls mean while binding: the sources of the query (layout), the query
 * around it (outer, for correlated subqueries; frame holds that outer row at run time), result-column
 * aliases keyed by normalised name where allowed (an alias stands for its expression), and what an
 * aggregate call does here (see Aggregates.Context).
 */
record Scope(Database db, Layout layout, Map<String, Expr> aliases, Aggregates.Context agg, Scope outer,
             Frame frame) {

    /** A scope with no sources: VALUES, LIMIT. */
    static Scope empty(Database db) {
        return new Scope(db, Layout.EMPTY, null, Aggregates.MISUSE, null, new Frame());
    }

    /** The scope of UPDATE / DELETE: the target table is the one source, named by its table name. */
    static Scope ofTable(Database db, Table t) {
        return new Scope(db, Layout.EMPTY.plus(t.name, t.columns), null, Aggregates.MISUSE, null, new Frame());
    }

    int width() {
        return layout.width();
    }

    List<Source> sources() {
        return layout.sources();
    }

    Scope withLayout(Layout l) {
        return new Scope(db, l, aliases, agg, outer, frame);
    }

    Scope withAliases(Map<String, Expr> a) {
        return new Scope(db, layout, a, agg, outer, frame);
    }

    Scope withAgg(Aggregates.Context c) {
        return new Scope(db, layout, aliases, c, outer, frame);
    }
}
