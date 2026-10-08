package sqlengine.exec;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;
import sqlengine.value.Values;

/** Runs a SELECT (1.7) and appends its printed rows. */
final class SelectExecutor {
    private final Database db;

    SelectExecutor(Database db) {
        this.db = db;
    }

    /** An ORDER BY term resolved to either a result column or an expression on the table row. */
    private record SortKey(int resultIndex, Node node, boolean desc, boolean nullsFirst) { }

    void run(Select q, StringBuilder out) {
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
        List<Object[]> source = t == null ? List.<Object[]>of(new Object[0]) : t.rows();
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
