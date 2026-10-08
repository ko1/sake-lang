package sqlengine.exec;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;
import sqlengine.value.SqlType;

/** Binds a SELECT (names, aggregates, ORDER BY / GROUP BY ordinals) into a runnable Query. */
final class QueryCompiler {
    private QueryCompiler() { }

    /** Name used for a result column that has neither alias nor column name; no identifier can equal it. */
    private static final String UNNAMED = "\u0000";

    /** Compiles q; outer is the scope of the enclosing query for a correlated subquery, else null. */
    static Query compile(Database db, Select q, Scope outer) {
        Frame frame = new Frame();
        FromPlan from = q.from() == null ? FromPlan.none()
            : FromPlan.compile(q.from(), new Scope(db, Layout.EMPTY, null, Aggregates.MISUSE, outer, frame));
        Layout layout = from.layout();
        boolean aggregate = !q.groupBy().isEmpty() || q.columns().stream()
            .anyMatch(rc -> rc.expr() != null && Aggregates.firstAggregate(rc.expr()) != null);
        Aggregates.Collector collector = new Aggregates.Collector();
        Aggregates.Context aggs = aggregate ? collector : Aggregates.MISUSE;

        // result columns (names here are source columns only)
        Scope resultScope = new Scope(db, layout, null, aggs, outer, frame);
        List<Expr> resultExprs = new ArrayList<>();
        List<Node> results = new ArrayList<>();
        List<Column> outputs = new ArrayList<>();
        Map<String, Integer> aliasIndex = new HashMap<>();
        Map<String, Expr> aliasExprs = new HashMap<>();
        for (ResultColumn rc : q.columns()) {
            if (rc.expr() == null) {
                expandStar(rc, layout, resultExprs, results, outputs);
            } else {
                if (rc.alias() != null) {
                    aliasIndex.put(Names.norm(rc.alias()), results.size());
                    aliasExprs.put(Names.norm(rc.alias()), rc.expr());
                }
                resultExprs.add(rc.expr());
                Node node = Binder.bind(rc.expr(), resultScope);
                results.add(node);
                outputs.add(outputColumn(rc, node, layout));
            }
        }
        if (q.having() != null && !aggregate) throw new SqlError("HAVING clause on a non-aggregate query");

        Node where = q.where() == null ? null
            : Binder.bind(q.where(), new Scope(db, layout, aliasExprs, Aggregates.MISUSE, outer, frame));
        Scope groupScope = new Scope(db, layout, aliasExprs, Aggregates.IN_GROUP_BY, outer, frame);
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
        Scope afterGroup = new Scope(db, layout, aliasExprs, aggregate ? collector : Aggregates.IN_PLAIN_ORDER_BY,
            outer, frame);
        Node having = q.having() == null ? null : Binder.bind(q.having(), afterGroup);
        List<Query.SortKey> keys = new ArrayList<>();
        for (int i = 0; i < q.orderBy().size(); i++) {
            keys.add(sortKey(q.orderBy().get(i), i + 1, results.size(), aliasIndex, afterGroup));
        }
        Scope noRow = Scope.empty(db);
        long limit = q.limit() == null ? -1 : constant(q.limit(), noRow);
        long offset = q.offset() == null ? 0 : Math.max(0, constant(q.offset(), noRow));
        return new Query(outputs, from, where, aggregate, groupBy, having, collector, results, q.distinct(), keys,
            limit, offset);
    }

    /** "*" or "q.*": every source column in order (4.2), minus the right copies of USING columns for "*". */
    private static void expandStar(ResultColumn rc, Layout layout, List<Expr> exprs, List<Node> results,
                                   List<Column> outputs) {
        if (layout.sources().isEmpty()) throw new SqlError("no tables specified");
        Source only = null;
        if (rc.starOf() != null) {
            only = layout.source(rc.starOf());
            if (only == null) throw new SqlError("no such table: " + rc.starOf());
        }
        for (Source s : layout.sources()) {
            if (only != null && s != only) continue;
            for (int i = 0; i < s.columns().size(); i++) {
                int flat = s.offset() + i;
                if (only == null && layout.isHidden(flat)) continue;
                Column c = s.columns().get(i);
                exprs.add(new Name(s.name(), c.name()));
                results.add(new Binder.ColumnNode(flat, c.type()));
                outputs.add(new Column(c.name(), c.type(), false, null));
            }
        }
    }

    /** The subquery-source column (4.1) for a result column: alias, else a plain reference's name and affinity. */
    private static Column outputColumn(ResultColumn rc, Node node, Layout layout) {
        String name = rc.alias();
        SqlType affinity = null;
        if (rc.expr() instanceof Name n) {
            affinity = node.affinity();
            if (name == null) {
                name = node instanceof Binder.ColumnNode cn && cn.idx() < layout.width()
                    ? layout.column(cn.idx()).name() : n.name();
            }
        }
        return new Column(name != null ? name : UNNAMED, affinity, false, null);
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

    private static Query.SortKey sortKey(OrderTerm term, int position, int nResults,
                                         Map<String, Integer> aliasIndex, Scope scope) {
        Ordering.Key order = Ordering.Key.of(term);
        Expr e = term.expr();
        Long k = ordinalTerm(e);
        if (k != null) {
            checkOrdinal(k, position, nResults, "ORDER BY");
            return new Query.SortKey((int) (k - 1), null, order);
        }
        if (e instanceof Name n && n.qualifier() == null) {
            Integer idx = aliasIndex.get(Names.norm(n.name()));
            if (idx != null) return new Query.SortKey(idx, null, order);
        }
        return new Query.SortKey(-1, Binder.bind(e, scope), order);
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
    private static long constant(Expr e, Scope noRow) {
        Object v = Binder.bind(e, noRow).eval(null);
        if (v == null) throw new SqlError("datatype mismatch");
        Number n = sqlengine.value.Values.toNumber(v);
        return n instanceof Long l ? l : (long) n.doubleValue();
    }
}
