package sqlengine.exec;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;
import sqlengine.value.Values;

/** INSERT, UPDATE and DELETE (1.5, 2.2, 5.4). A statement that fails leaves the table as it was. */
final class Dml {
    private final Database db;

    Dml(Database db) {
        this.db = db;
    }

    /** The table a statement may change: a view is refused (5.3). */
    private Table writable(String name) {
        View v = db.findView(name);
        if (v != null && db.find(name) == null) throw new SqlError("cannot modify " + v.name() + " because it is a view");
        return db.require(name);
    }

    void insert(Insert ins) {
        if (ins.rows() != null) {
            int width = ins.rows().get(0).size();
            for (List<Expr> r : ins.rows()) {
                if (r.size() != width) throw new SqlError("all VALUES must have the same number of terms");
            }
        }
        Table t = writable(ins.table());
        Query source = ins.select() == null ? null : QueryCompiler.compile(db, Ctes.NONE, ins.select(), null);
        int width = source == null ? ins.rows().get(0).size() : source.outputs().size();
        int[] target = targetColumns(ins, t, width);
        List<Object[]> values = source == null ? evalRows(ins.rows()) : source.run();
        List<Object[]> before = t.snapshot();
        try {
            for (Object[] vals : values) {
                Object[] supplied = new Object[t.rowidSlot() + 1];
                boolean[] given = new boolean[supplied.length];
                for (int k = 0; k < width; k++) {
                    supplied[target[k]] = vals[k];
                    given[target[k]] = true;
                }
                t.insert(t.newRow(supplied, given));
            }
        } catch (RuntimeException e) {
            t.restore(before);
            throw e;
        }
    }

    /** The column index for each of the width supplied values, or the count error. */
    private static int[] targetColumns(Insert ins, Table t, int width) {
        int[] target = new int[width];
        if (ins.columns() == null) {
            if (width != t.columns.size()) {
                throw new SqlError("table " + ins.table() + " has " + t.columns.size() + " columns but "
                    + width + " values were supplied");
            }
            for (int k = 0; k < width; k++) target[k] = k;
            return target;
        }
        List<String> names = ins.columns();
        for (int k = 0; k < names.size(); k++) {
            int idx = t.columnIndex(names.get(k));
            if (idx < 0 && Names.isRowidName(names.get(k))) idx = t.rowidSlot(); // 7.3
            if (idx < 0) throw new SqlError("table " + ins.table() + " has no column named " + names.get(k));
            if (k < width) target[k] = idx;
        }
        if (names.size() != width) throw new SqlError(width + " values for " + names.size() + " columns");
        return target;
    }

    private List<Object[]> evalRows(List<List<Expr>> rows) {
        Scope noRow = Scope.empty(db);
        List<Object[]> out = new ArrayList<>();
        for (List<Expr> r : rows) {
            Object[] vals = new Object[r.size()];
            for (int k = 0; k < vals.length; k++) vals[k] = Binder.bind(r.get(k), noRow).eval(null);
            out.add(vals);
        }
        return out;
    }

    void update(Update u) {
        Table t = writable(u.table());
        Scope scope = Scope.ofTable(db, t);
        Map<Integer, Node> sets = new LinkedHashMap<>(); // later assignments to a column replace earlier
        for (Assignment a : u.assignments()) {
            int idx = t.columnIndex(a.column());
            if (idx < 0 && Names.isRowidName(a.column())) idx = t.rowidSlot(); // 7.3
            if (idx < 0) throw new SqlError("no such column: " + a.column());
            Node value = Binder.bind(a.value(), scope);
            sets.put(idx, value);
            // the INTEGER PRIMARY KEY column and the rowid are one value: assigning either assigns both
            if (t.rowKey() >= 0 && (idx == t.rowKey() || idx == t.rowidSlot())) {
                sets.put(idx == t.rowKey() ? t.rowidSlot() : t.rowKey(), value);
            }
        }
        Node where = u.where() == null ? null : Binder.bind(u.where(), scope);
        List<Object[]> before = t.snapshot();
        try {
            for (int i = 0; i < before.size(); i++) {
                Object[] old = before.get(i);
                if (where != null && !Boolean.TRUE.equals(Values.truth(where.eval(old)))) continue;
                Object[] raw = old.clone();
                sets.forEach((idx, node) -> raw[idx] = node.eval(old));
                t.replace(i, raw);
            }
        } catch (RuntimeException e) {
            t.restore(before);
            throw e;
        }
    }

    void delete(Delete d) {
        Table t = writable(d.table());
        Node where = d.where() == null ? null : Binder.bind(d.where(), Scope.ofTable(db, t));
        t.deleteIf(row -> where == null || Boolean.TRUE.equals(Values.truth(where.eval(row))));
    }
}
