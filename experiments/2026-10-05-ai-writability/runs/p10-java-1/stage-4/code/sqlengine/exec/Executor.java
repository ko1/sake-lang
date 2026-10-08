package sqlengine.exec;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Values;

/** Runs one parsed statement against the database. Output goes to out only if the statement succeeds. */
public final class Executor {
    private final Database db;
    private final SelectExecutor selects;

    public Executor(Database db) {
        this.db = db;
        this.selects = new SelectExecutor(db);
    }

    public void execute(Stmt s, StringBuilder out) {
        if (s instanceof CreateTable c) createTable(c);
        else if (s instanceof Update u) update(u);
        else if (s instanceof Delete d) delete(d);
        else if (s instanceof DropTable d) dropTable(d);
        else if (s instanceof Insert i) insert(i);
        else selects.run((Select) s, out);
    }

    // ---- DDL ----
    private void createTable(CreateTable c) {
        if (db.find(c.name()) != null) {
            if (c.ifNotExists()) return;
            throw new SqlError("table " + c.name() + " already exists");
        }
        db.add(SchemaBuilder.build(c));
    }

    private void dropTable(DropTable d) {
        if (db.find(d.name()) == null) {
            if (d.ifExists()) return;
            throw new SqlError("no such table: " + d.name());
        }
        db.remove(d.name());
    }

    // ---- INSERT ----
    private void insert(Insert ins) {
        int width = ins.rows().get(0).size();
        for (List<Expr> r : ins.rows()) {
            if (r.size() != width) throw new SqlError("all VALUES must have the same number of terms");
        }
        Table t = db.require(ins.table());
        int[] target = new int[width]; // column index for each supplied value
        if (ins.columns() == null) {
            if (width != t.columns.size()) {
                throw new SqlError("table " + ins.table() + " has " + t.columns.size() + " columns but "
                    + width + " values were supplied");
            }
            for (int k = 0; k < width; k++) target[k] = k;
        } else {
            List<String> names = ins.columns();
            for (int k = 0; k < names.size(); k++) {
                int idx = t.columnIndex(names.get(k));
                if (idx < 0) throw new SqlError("table " + ins.table() + " has no column named " + names.get(k));
                if (k < width) target[k] = idx;
            }
            if (names.size() != width) throw new SqlError(width + " values for " + names.size() + " columns");
        }
        Scope noRow = Scope.empty(db);
        List<Object[]> before = t.snapshot();
        try {
            for (List<Expr> r : ins.rows()) {
                Object[] supplied = new Object[t.columns.size()];
                boolean[] given = new boolean[supplied.length];
                for (int k = 0; k < width; k++) {
                    supplied[target[k]] = Binder.bind(r.get(k), noRow).eval(null);
                    given[target[k]] = true;
                }
                t.insert(t.newRow(supplied, given));
            }
        } catch (RuntimeException e) {
            t.restore(before);
            throw e;
        }
    }

    // ---- UPDATE and DELETE ----
    private void update(Update u) {
        Table t = db.require(u.table());
        Scope scope = Scope.ofTable(db, t);
        Map<Integer, Node> sets = new LinkedHashMap<>(); // later assignments to a column replace earlier
        for (Assignment a : u.assignments()) {
            int idx = t.columnIndex(a.column());
            if (idx < 0) throw new SqlError("no such column: " + a.column());
            sets.put(idx, Binder.bind(a.value(), scope));
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

    private void delete(Delete d) {
        Table t = db.require(d.table());
        Node where = d.where() == null ? null : Binder.bind(d.where(), Scope.ofTable(db, t));
        t.deleteIf(row -> where == null || Boolean.TRUE.equals(Values.truth(where.eval(row))));
    }
}
