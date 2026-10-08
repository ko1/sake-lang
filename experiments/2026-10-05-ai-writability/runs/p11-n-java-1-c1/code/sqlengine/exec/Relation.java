package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;
import sqlengine.parse.SqlError;

/** What a name in FROM stands for: a table, a view, a cte (5.2, 5.3). Rows are computed when asked. */
record Relation(List<Column> columns, Supplier<List<Object[]>> rows) {

    /** The relation of q's rows, its columns named by names (null: keep q's names); what names the error says. */
    static Relation of(Query q, List<String> names, String what) {
        List<Column> cols = q.outputs();
        if (names != null) {
            if (names.size() != cols.size()) {
                throw new SqlError(what + " has " + cols.size() + " values for " + names.size() + " columns");
            }
            List<Column> renamed = new ArrayList<>();
            for (int i = 0; i < cols.size(); i++) {
                Column c = cols.get(i);
                renamed.add(new Column(names.get(i), c.type(), false, null, c.collation(), c.collationExplicit()));
            }
            cols = renamed;
        }
        return new Relation(cols, q::run);
    }
}
