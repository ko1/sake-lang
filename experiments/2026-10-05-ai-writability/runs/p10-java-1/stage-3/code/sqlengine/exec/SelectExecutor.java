package sqlengine.exec;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
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

    /** An ORDER BY term resolved to either a result column or an expression on the evaluation row. */
    private record SortKey(int resultIndex, Node node, Ordering.Key order) { }

    void run(Select q, StringBuilder out) {
        Table t = q.from() == null ? null : db.require(q.from());
        List<Column> cols = t == null ? List.of() : t.columns;
        boolean aggregate = !q.groupBy().isEmpty() || q.columns().stream()
            .anyMatch(rc -> rc.expr() != null && Aggregates.firstAggregate(rc.expr()) != null);
        Aggregates.Collector collector = new Aggregates.Collector();
        Aggregates.Context aggs = aggregate ? collector : Aggregates.MISUSE;

        // result columns (names here are table columns only)
        Scope resultScope = new Scope(cols, null, aggs);
        List<Expr> resultExprs = new ArrayList<>();
        List<Node> results = new ArrayList<>();
        Map<String, Integer> aliasIndex = new HashMap<>();
        Map<String, Expr> aliasExprs = new HashMap<>();
        for (ResultColumn rc : q.columns()) {
            if (rc.expr() == null) {
                if (t == null) throw new SqlError("no tables specified");
                for (int i = 0; i < cols.size(); i++) {
                    resultExprs.add(new Name(cols.get(i).name()));
                    results.add(new Binder.ColumnNode(i, cols.get(i).type()));
                }
            } else {
                if (rc.alias() != null) {
                    aliasIndex.put(Names.norm(rc.alias()), results.size());
                    aliasExprs.put(Names.norm(rc.alias()), rc.expr());
                }
                resultExprs.add(rc.expr());
                results.add(Binder.bind(rc.expr(), resultScope));
            }
        }
        if (q.having() != null && !aggregate) throw new SqlError("HAVING clause on a non-aggregate query");

        Node where = q.where() == null ? null
            : Binder.bind(q.where(), new Scope(cols, aliasExprs, Aggregates.MISUSE));
        Scope groupScope = new Scope(cols, aliasExprs, Aggregates.IN_GROUP_BY);
        List<Node> groupBy = new ArrayList<>();
        for (int i = 0; i < q.groupBy().size(); i++) {
            Expr term = q.groupBy().get(i);
            Long k = ordinalTerm(term);
            if (k != null) {
                checkOrdinal(k, i + 1, results.size(), "GROUP BY");
                term = resultExprs.get((int) (k - 1));
            }
            groupBy.add(Binder.bind(term, groupScope));
        }
        Scope afterGroup = new Scope(cols, aliasExprs, aggregate ? collector : Aggregates.IN_PLAIN_ORDER_BY);
        Node having = q.having() == null ? null : Binder.bind(q.having(), afterGroup);
        List<SortKey> keys = new ArrayList<>();
        for (int i = 0; i < q.orderBy().size(); i++) {
            keys.add(sortKey(q.orderBy().get(i), i + 1, results.size(), aliasIndex, afterGroup));
        }
        long limit = q.limit() == null ? -1 : constant(q.limit());
        long offset = q.offset() == null ? 0 : Math.max(0, constant(q.offset()));

        // rows to evaluate the result columns on: table rows, or one extended row per group
        List<Object[]> source = t == null ? List.<Object[]>of(new Object[0]) : t.rows();
        List<Object[]> rows = new ArrayList<>();
        for (Object[] row : source) {
            if (where == null || Boolean.TRUE.equals(Values.truth(where.eval(row)))) rows.add(row);
        }
        if (aggregate) rows = groupRows(rows, groupBy, having, collector, cols.size());

        List<Ordering.Key> orders = keys.stream().map(SortKey::order).toList();
        Set<List<Object>> seen = new HashSet<>();
        List<Object[][]> produced = new ArrayList<>(); // {result values, sort keys}
        for (Object[] row : rows) {
            Object[] vals = new Object[results.size()];
            for (int i = 0; i < vals.length; i++) vals[i] = results.get(i).eval(row);
            if (q.distinct() && !seen.add(groupKey(vals))) continue;
            Object[] ks = new Object[keys.size()];
            for (int i = 0; i < ks.length; i++) {
                SortKey k = keys.get(i);
                ks[i] = k.resultIndex() >= 0 ? vals[k.resultIndex()] : k.node().eval(row);
            }
            produced.add(new Object[][] {vals, ks});
        }
        if (!keys.isEmpty()) produced.sort((a, b) -> Ordering.compare(orders, a[1], b[1]));

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

    private static List<Object> groupKey(Object[] vals) {
        List<Object> key = new ArrayList<>(vals.length);
        for (Object v : vals) key.add(Values.groupKey(v));
        return key;
    }

    /**
     * Partitions rows by the GROUP BY values (3.3) and returns one extended row per group kept by HAVING:
     * the representative row followed by the group's aggregate results, where Collector's slots read them.
     */
    private static List<Object[]> groupRows(List<Object[]> rows, List<Node> groupBy, Node having,
                                            Aggregates.Collector collector, int width) {
        Map<List<Object>, List<Object[]>> groups = new LinkedHashMap<>();
        if (groupBy.isEmpty()) {
            groups.put(List.of(), rows); // the single group exists even without rows
        } else {
            for (Object[] row : rows) {
                Object[] key = new Object[groupBy.size()];
                for (int i = 0; i < key.length; i++) key[i] = groupBy.get(i).eval(row);
                groups.computeIfAbsent(groupKey(key), k -> new ArrayList<>()).add(row);
            }
        }
        List<AggregateFunction> functions = collector.functions();
        AggregateFunction extreme = collector.singleExtreme();
        List<Object[]> result = new ArrayList<>();
        for (List<Object[]> group : groups.values()) {
            Object[] rep = group.isEmpty() ? new Object[width] : group.get(0);
            if (extreme != null) {
                Object[] r = extreme.extremeRow(group);
                if (r != null) rep = r;
            }
            Object[] ext = Arrays.copyOf(rep, width + functions.size());
            for (int i = 0; i < functions.size(); i++) ext[width + i] = functions.get(i).compute(group);
            if (having == null || Boolean.TRUE.equals(Values.truth(having.eval(ext)))) result.add(ext);
        }
        return result;
    }

    /** k if term is an integer literal k or "-" directly followed by one (an ORDER BY / GROUP BY ordinal). */
    private static Long ordinalTerm(Expr e) {
        if (e instanceof Literal l && l.value() instanceof Long v) return v;
        if (e instanceof Unary u && u.op().equals("-") && u.operand() instanceof Literal l
            && l.value() instanceof Long v) {
            return -v;
        }
        return null;
    }

    private static void checkOrdinal(long k, int position, int nResults, String clause) {
        if (k < 1 || k > nResults) {
            throw new SqlError(ordinal(position) + " " + clause + " term out of range - should be between 1 and "
                + nResults);
        }
    }

    private SortKey sortKey(OrderTerm term, int position, int nResults, Map<String, Integer> aliasIndex,
                            Scope scope) {
        Ordering.Key order = Ordering.Key.of(term);
        Expr e = term.expr();
        Long k = ordinalTerm(e);
        if (k != null) {
            checkOrdinal(k, position, nResults, "ORDER BY");
            return new SortKey((int) (k - 1), null, order);
        }
        if (e instanceof Name n) {
            Integer idx = aliasIndex.get(Names.norm(n.name()));
            if (idx != null) return new SortKey(idx, null, order);
        }
        return new SortKey(-1, Binder.bind(e, scope), order);
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
