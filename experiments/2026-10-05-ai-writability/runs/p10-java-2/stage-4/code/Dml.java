import java.util.ArrayList;
import java.util.List;

/** INSERT, UPDATE and DELETE. A statement that fails leaves its table as it was. */
final class Dml {
    private final Catalog catalog;

    Dml(Catalog catalog) {
        this.catalog = catalog;
    }

    void insert(Stmt.Insert ins) {
        Table t = catalog.get(ins.table());
        int width = ins.rows().get(0).size();
        for (List<Expr> row : ins.rows()) {
            if (row.size() != width) throw new SqlError("all VALUES must have the same number of terms");
        }
        int[] targets = targetColumns(t, ins);
        if (ins.columns() == null) {
            if (width != targets.length) {
                throw new SqlError("table " + ins.table() + " has " + targets.length + " columns but " + width
                    + " values were supplied");
            }
        } else if (width != targets.length) {
            throw new SqlError(width + " values for " + targets.length + " columns");
        }
        Resolver noRow = Resolver.empty(catalog);
        List<List<Expr>> resolved = new ArrayList<>();
        for (List<Expr> row : ins.rows()) resolved.add(row.stream().map(noRow::resolve).toList());
        int start = t.rows.size();
        try {
            for (List<Expr> row : resolved) {
                Object[] raw = t.defaults.clone();
                for (int k = 0; k < targets.length; k++) raw[targets[k]] = Evaluator.eval(row.get(k), Env.of(raw));
                t.rows.add(RowChecker.prepare(t, raw, -1));
            }
        } catch (SqlError e) {
            t.rows.subList(start, t.rows.size()).clear();
            throw e;
        }
    }

    /** Table column index for each supplied value position. */
    private static int[] targetColumns(Table t, Stmt.Insert ins) {
        if (ins.columns() == null) {
            int[] all = new int[t.columns.size()];
            for (int i = 0; i < all.length; i++) all[i] = i;
            return all;
        }
        int[] idx = new int[ins.columns().size()];
        for (int i = 0; i < idx.length; i++) {
            idx[i] = t.columnIndex(ins.columns().get(i));
            if (idx[i] < 0) {
                throw new SqlError("table " + ins.table() + " has no column named " + ins.columns().get(i));
            }
        }
        return idx;
    }

    void update(Stmt.Update u) {
        Table t = catalog.get(u.table());
        Resolver r = Resolver.of(catalog, t);
        Expr[] assigned = new Expr[t.columns.size()];
        for (Stmt.Assignment a : u.sets()) {
            int c = t.columnIndex(a.column());
            if (c < 0) throw new SqlError("no such column: " + a.column());
            assigned[c] = r.resolve(a.value());
        }
        Expr where = u.where() == null ? null : r.resolve(u.where());
        List<Object[]> backup = new ArrayList<>(t.rows);
        try {
            for (int i = 0; i < t.rows.size(); i++) {
                Object[] old = t.rows.get(i);
                if (where != null && Values.truth(Evaluator.eval(where, Env.of(old))) != Boolean.TRUE) continue;
                Object[] raw = old.clone();
                for (int c = 0; c < raw.length; c++) if (assigned[c] != null) raw[c] = Evaluator.eval(assigned[c], Env.of(old));
                t.rows.set(i, RowChecker.prepare(t, raw, i));
            }
        } catch (SqlError e) {
            t.rows.clear();
            t.rows.addAll(backup);
            throw e;
        }
    }

    void delete(Stmt.Delete d) {
        Table t = catalog.get(d.table());
        if (d.where() == null) {
            t.rows.clear();
            return;
        }
        Expr where = Resolver.of(catalog, t).resolve(d.where());
        t.rows.removeIf(row -> Values.truth(Evaluator.eval(where, Env.of(row))) == Boolean.TRUE);
    }
}
