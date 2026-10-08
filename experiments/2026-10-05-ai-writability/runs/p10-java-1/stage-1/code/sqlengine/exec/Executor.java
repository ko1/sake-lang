package sqlengine.exec;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;
import sqlengine.value.Values;

/** Runs one parsed statement against the database. Output goes to out only if the statement succeeds. */
public final class Executor {
    private final Database db;

    public Executor(Database db) {
        this.db = db;
    }

    public void execute(Stmt s, StringBuilder out) {
        if (s instanceof CreateTable c) createTable(c);
        else if (s instanceof DropTable d) dropTable(d);
        else if (s instanceof Insert i) insert(i);
        else select((Select) s, out);
    }

    // ---- DDL ----
    private void createTable(CreateTable c) {
        if (db.find(c.name()) != null) {
            if (c.ifNotExists()) return;
            throw new SqlError("table " + c.name() + " already exists");
        }
        Set<String> seen = new HashSet<>();
        List<Column> cols = new ArrayList<>();
        for (ColumnDef d : c.columns()) {
            if (!seen.add(Names.norm(d.name()))) throw new SqlError("duplicate column name: " + d.name());
            cols.add(new Column(d.name(), d.type()));
        }
        db.add(new Table(c.name(), cols));
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
        Scope noRow = new Scope(List.of(), null);
        List<Object[]> staged = new ArrayList<>();
        for (List<Expr> r : ins.rows()) {
            Object[] row = new Object[t.columns.size()];
            for (int k = 0; k < width; k++) {
                Object v = Binder.bind(r.get(k), noRow).eval(null);
                Column col = t.columns.get(target[k]);
                row[target[k]] = col.store(v, t.name);
            }
            staged.add(row);
        }
        t.rows.addAll(staged);
    }

    // ---- SELECT ----
    /** An ORDER BY term resolved to either a result column or an expression on the table row. */
    private record SortKey(int resultIndex, Node node, boolean desc, boolean nullsFirst) { }

    private void select(Select q, StringBuilder out) {
        Table t = q.from() == null ? null : db.require(q.from());
        List<Column> cols = t == null ? List.of() : t.columns;
        Scope plain = new Scope(cols, null);

        // result columns (names here are table columns only)
        List<Node> results = new ArrayList<>();
        Map<String, Integer> aliasIndex = new HashMap<>();
        for (ResultColumn rc : q.columns()) {
            if (rc.expr() == null) {
                if (t == null) throw new SqlError("no tables specified");
                for (int i = 0; i < cols.size(); i++) results.add(new Binder.ColumnNode(i, cols.get(i).type()));
            } else {
                if (rc.alias() != null) aliasIndex.put(Names.norm(rc.alias()), results.size());
                results.add(Binder.bind(rc.expr(), plain));
            }
        }
        Map<String, Node> aliasNodes = new HashMap<>();
        aliasIndex.forEach((k, v) -> aliasNodes.put(k, results.get(v)));
        Scope withAliases = plain.withAliases(aliasNodes);

        Node where = q.where() == null ? null : Binder.bind(q.where(), withAliases);
        List<SortKey> keys = new ArrayList<>();
        for (int i = 0; i < q.orderBy().size(); i++) {
            keys.add(sortKey(q.orderBy().get(i), i + 1, results.size(), aliasIndex, withAliases));
        }
        long limit = q.limit() == null ? -1 : constant(q.limit());
        long offset = q.offset() == null ? 0 : Math.max(0, constant(q.offset()));

        // produce rows
        List<Object[]> source = t == null ? List.<Object[]>of(new Object[0]) : t.rows;
        List<Object[][]> produced = new ArrayList<>(); // {result values, sort keys}
        for (Object[] row : source) {
            if (where != null && !Boolean.TRUE.equals(Values.truth(where.eval(row)))) continue;
            Object[] vals = new Object[results.size()];
            for (int i = 0; i < vals.length; i++) vals[i] = results.get(i).eval(row);
            Object[] ks = new Object[keys.size()];
            for (int i = 0; i < ks.length; i++) {
                SortKey k = keys.get(i);
                ks[i] = k.resultIndex() >= 0 ? vals[k.resultIndex()] : k.node().eval(row);
            }
            produced.add(new Object[][] {vals, ks});
        }
        if (!keys.isEmpty()) produced.sort((a, b) -> compareKeys(keys, a[1], b[1]));

        long end = limit < 0 ? Long.MAX_VALUE : offset + limit;
        StringBuilder buf = new StringBuilder();
        for (long i = offset; i < produced.size() && i < end; i++) {
            Object[] vals = produced.get((int) i)[0];
            for (int c = 0; c < vals.length; c++) {
                if (c > 0) buf.append('|');
                buf.append(Values.display(vals[c]));
            }
            buf.append('\n');
        }
        out.append(buf);
    }

    private static int compareKeys(List<SortKey> keys, Object[] a, Object[] b) {
        for (int i = 0; i < keys.size(); i++) {
            SortKey k = keys.get(i);
            Object x = a[i];
            Object y = b[i];
            int c;
            if (x == null || y == null) {
                if (x == y) continue;
                c = (x == null) == k.nullsFirst() ? -1 : 1;
                if (c != 0) return c; // explicit placement of NULLs, not reversed by DESC
            } else {
                c = Values.compare(x, y);
                if (k.desc()) c = -c;
            }
            if (c != 0) return c;
        }
        return 0;
    }

    private SortKey sortKey(OrderTerm term, int position, int nResults, Map<String, Integer> aliasIndex,
                            Scope scope) {
        boolean nullsFirst = term.nullsFirst() != null ? term.nullsFirst() : !term.desc();
        Expr e = term.expr();
        Long k = null;
        if (e instanceof Literal l && l.value() instanceof Long v) k = v;
        else if (e instanceof Unary u && u.op().equals("-") && u.operand() instanceof Literal l
                 && l.value() instanceof Long v) k = -v;
        if (k != null) {
            if (k < 1 || k > nResults) {
                throw new SqlError(ordinal(position) + " ORDER BY term out of range - should be between 1 and "
                    + nResults);
            }
            return new SortKey((int) (k - 1), null, term.desc(), nullsFirst);
        }
        if (e instanceof Name n) {
            Integer idx = aliasIndex.get(Names.norm(n.name()));
            if (idx != null) return new SortKey(idx, null, term.desc(), nullsFirst);
        }
        return new SortKey(-1, Binder.bind(e, scope), term.desc(), nullsFirst);
    }

    private static String ordinal(int n) {
        int m100 = n % 100;
        String suffix = "th";
        if (m100 < 11 || m100 > 13) {
            switch (n % 10) {
                case 1: suffix = "st"; break;
                case 2: suffix = "nd"; break;
                case 3: suffix = "rd"; break;
                default: break;
            }
        }
        return n + suffix;
    }

    /** Value of a LIMIT/OFFSET expression (no row in scope) as an integer. */
    private long constant(Expr e) {
        Object v = Binder.bind(e, new Scope(List.of(), null)).eval(null);
        if (v == null) throw new SqlError("datatype mismatch");
        Number n = Values.toNumber(v);
        return n instanceof Long l ? l : (long) n.doubleValue();
    }
}
