package sqlengine.exec;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Collation;
import sqlengine.value.Names;
import sqlengine.value.SqlType;

/** Binds a SELECT (names, aggregates, ORDER BY / GROUP BY ordinals) into a runnable Query. */
final class QueryCompiler {
    private QueryCompiler() { }

    /** Name used for a result column that has neither alias nor column name; no identifier can equal it. */
    private static final String UNNAMED = "\u0000";

    /** Compiles a select nested in the query bound in outer (a correlated subquery). */
    static Query compile(Select q, Scope outer) {
        return compile(outer.db(), outer.ctes(), q, outer);
    }

    /** Compiles q seeing the ctes visible; outer is the scope of the enclosing query for a correlated subquery, else null. */
    static Query compile(Database db, Ctes visible, Select q, Scope outer) {
        Ctes ctes = Ctes.declare(db, visible, q.with());
        if (q.rest().isEmpty()) {
            long[] w = window(db, ctes, q);
            return compileCore(db, ctes, q.first(), q.orderBy(), w[0], w[1], outer);
        }
        return compileCompound(db, ctes, q, outer);
    }

    /** {limit, offset} of q's LIMIT / OFFSET: -1 for no limit, 0 for no offset. */
    static long[] window(Database db, Ctes ctes, Select q) {
        Scope noRow = Scope.empty(db).withCtes(ctes);
        long limit = q.limit() == null ? -1 : constant(q.limit(), noRow);
        long offset = q.offset() == null ? 0 : Math.max(0, constant(q.offset(), noRow));
        return new long[] {limit, offset};
    }

    /** A compound select (5.1): its parts are compiled alone, ORDER BY / LIMIT apply to the combined rows. */
    private static Query compileCompound(Database db, Ctes ctes, Select q, Scope outer) {
        List<Query> parts = new ArrayList<>();
        parts.add(compileCore(db, ctes, q.first(), List.of(), -1, 0, outer));
        List<CompoundOp> ops = new ArrayList<>();
        for (CompoundTerm t : q.rest()) {
            Query part = compileCore(db, ctes, t.select(), List.of(), -1, 0, outer);
            if (part.outputs().size() != parts.get(0).outputs().size()) {
                throw new SqlError("SELECTs to the left and right of " + t.op().text
                    + " do not have the same number of result columns");
            }
            ops.add(t.op());
            parts.add(part);
        }
        // 7.4: a column takes the collation of the first select, left to right, whose column has one
        Collation[] colls = new Collation[parts.get(0).outputs().size()];
        for (int c = 0; c < colls.length; c++) {
            colls[c] = Collation.BINARY;
            for (Query part : parts) {
                Collation found = part.outputs().get(c).collation();
                if (found != null) {
                    colls[c] = found;
                    break;
                }
            }
        }
        List<CompoundQuery.SortKey> keys = new ArrayList<>();
        for (int i = 0; i < q.orderBy().size(); i++) {
            OrderTerm term = q.orderBy().get(i);
            Expr e = term.expr();
            Collation own = null;
            if (e instanceof Collate c) {
                own = Collation.lookup(c.collation());
                e = c.value();
            }
            int column = compoundOrderColumn(e, i + 1, parts);
            keys.add(new CompoundQuery.SortKey(column, Ordering.Key.of(term, own != null ? own : colls[column])));
        }
        long[] w = window(db, ctes, q);
        return new CompoundQuery(parts.get(0), ops, parts.subList(1, parts.size()), keys, colls, w[0], w[1]);
    }

    /** The result column an ORDER BY term of a compound select means: an ordinal, or a name tried on each part. */
    private static int compoundOrderColumn(Expr e, int position, List<Query> parts) {
        int width = parts.get(0).outputs().size();
        Long k = ordinalTerm(e);
        if (k != null) {
            checkOrdinal(k, position, width, "ORDER BY");
            return (int) (k - 1);
        }
        if (e instanceof Name n && n.qualifier() == null) {
            for (Query part : parts) {
                List<Column> cols = part.outputs();
                for (int c = 0; c < cols.size(); c++) {
                    if (Names.same(cols.get(c).name(), n.name())) return c;
                }
            }
        }
        throw new SqlError(ordinal(position) + " ORDER BY term does not match any column in the result set");
    }

    /** Compiles one simple select with the given ORDER BY and window (limit, offset). */
    private static Query compileCore(Database db, Ctes ctes, SelectCore q, List<OrderTerm> orderBy, long limit,
                                     long offset, Scope outer) {
        Frame frame = new Frame();
        FromPlan from = q.from() == null ? FromPlan.none()
            : FromPlan.compile(q.from(), new Scope(db, ctes, Layout.EMPTY, null, Aggregates.MISUSE, outer, frame,
                Windows.REJECT));
        Layout layout = from.layout();
        boolean aggregate = !q.groupBy().isEmpty() || q.columns().stream()
            .anyMatch(rc -> rc.expr() != null && Aggregates.firstAggregate(rc.expr()) != null);
        Aggregates.Collector collector = new Aggregates.Collector();
        Aggregates.Context aggs = aggregate ? collector : Aggregates.MISUSE;
        Windows.Collector windows = new Windows.Collector(collector, layout.width(), q.windows());

        // result columns (names here are source columns only)
        Scope resultScope = new Scope(db, ctes, layout, null, aggs, outer, frame, windows);
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
            : Binder.bind(q.where(), new Scope(db, ctes, layout, aliasExprs, Aggregates.MISUSE, outer, frame,
                Windows.REJECT));
        Scope groupScope = new Scope(db, ctes, layout, aliasExprs, Aggregates.IN_GROUP_BY, outer, frame,
            Windows.REJECT);
        List<Node> groupBy = new ArrayList<>();
        for (int i = 0; i < q.groupBy().size(); i++) {
            Expr term = q.groupBy().get(i);
            Collate collate = term instanceof Collate c ? c : null; // GROUP BY 1 COLLATE n is allowed (7.4)
            Long k = ordinalTerm(collate != null ? collate.value() : term);
            if (k != null) {
                checkOrdinal(k, i + 1, results.size(), "GROUP BY");
                term = resultExprs.get((int) (k - 1));
                if (collate != null) term = new Collate(term, collate.collation());
            }
            groupBy.add(Binder.bind(term, groupScope));
        }
        Scope afterGroup = new Scope(db, ctes, layout, aliasExprs, aggregate ? collector : Aggregates.IN_PLAIN_ORDER_BY,
            outer, frame, windows);
        Node having = q.having() == null ? null : Binder.bind(q.having(), afterGroup.withWindows(Windows.REJECT));
        List<SelectQuery.SortKey> keys = new ArrayList<>();
        for (int i = 0; i < orderBy.size(); i++) {
            keys.add(sortKey(orderBy.get(i), i + 1, results, aliasIndex, afterGroup));
        }
        return new SelectQuery(outputs, from, where, aggregate, groupBy, having, collector, windows, results, q.distinct(),
            keys, limit, offset);
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
                results.add(new Binder.ColumnNode(flat, c.type(), c.implicitCollation()));
                outputs.add(new Column(c.name(), c.type(), false, null, c.implicitCollation(), false));
            }
        }
    }

    /**
     * The subquery-source column (4.1) for a result column: alias, else a plain reference's name and affinity;
     * it carries the collation of the result expression (7.5).
     */
    private static Column outputColumn(ResultColumn rc, Node node, Layout layout) {
        String name = rc.alias();
        Collation coll = Node.collationOf(node);
        boolean explicit = node.explicitCollation() != null;
        SqlType affinity = null;
        if (rc.expr() instanceof Name n) {
            affinity = node.affinity();
            if (name == null) {
                name = node instanceof Binder.ColumnNode cn && cn.idx() < layout.width()
                    ? layout.column(cn.idx()).name() : n.name();
            }
        }
        return new Column(name != null ? name : UNNAMED, affinity, false, null, coll, explicit);
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

    /**
     * An ORDER BY term sorts under its own COLLATE, else the collation of the result column it stands for or of
     * its expression, else BINARY (7.4).
     */
    private static SelectQuery.SortKey sortKey(OrderTerm term, int position, List<Node> results,
                                         Map<String, Integer> aliasIndex, Scope scope) {
        Expr e = term.expr();
        Collation own = null;
        if (e instanceof Collate c) { // a result-column term may carry a COLLATE; other terms bind it below
            own = Collation.lookup(c.collation());
            e = c.value();
        }
        int column = -1;
        Long k = ordinalTerm(e);
        if (k != null) {
            checkOrdinal(k, position, results.size(), "ORDER BY");
            column = (int) (k - 1);
        } else if (e instanceof Name n && n.qualifier() == null) {
            Integer idx = aliasIndex.get(Names.norm(n.name()));
            if (idx != null) column = idx;
        }
        if (column >= 0) {
            Collation coll = own != null ? own : Node.collationOrBinary(results.get(column));
            return new SelectQuery.SortKey(column, null, Ordering.Key.of(term, coll));
        }
        Node node = Binder.bind(term.expr(), scope);
        return new SelectQuery.SortKey(-1, node, Ordering.Key.of(term, Node.collationOrBinary(node)));
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
