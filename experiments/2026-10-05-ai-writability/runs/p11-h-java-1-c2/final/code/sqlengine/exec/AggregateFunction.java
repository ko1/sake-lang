package sqlengine.exec;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import sqlengine.parse.Ast.Call;
import sqlengine.parse.Ast.OrderTerm;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;
import sqlengine.value.Values;

/** One bound aggregate call (3.2); compute() evaluates it over the rows of a group. */
final class AggregateFunction {
    private enum Kind { COUNT, SUM, TOTAL, AVG, MIN, MAX, GROUP_CONCAT }

    private final Kind kind;
    private final boolean distinct;
    private final Node arg;                 // null for count(*)
    private final Node separator;           // group_concat's second argument, or null
    private final List<Node> orderNodes;    // ORDER BY inside the call, evaluated on group rows
    private final List<Ordering.Key> order;

    private AggregateFunction(Kind kind, boolean distinct, Node arg, Node separator, List<Node> orderNodes,
                              List<Ordering.Key> order) {
        this.kind = kind;
        this.distinct = distinct;
        this.arg = arg;
        this.separator = separator;
        this.orderNodes = orderNodes;
        this.order = order;
    }

    /** Checks the argument count and binds the arguments (in a scope where aggregates are rejected). */
    static AggregateFunction bind(Call c, Scope scope) {
        String name = Names.norm(c.name());
        Kind kind = switch (name) {
            case "count" -> Kind.COUNT;
            case "sum" -> Kind.SUM;
            case "total" -> Kind.TOTAL;
            case "avg" -> Kind.AVG;
            case "min" -> Kind.MIN;
            case "max" -> Kind.MAX;
            default -> Kind.GROUP_CONCAT;
        };
        int n = c.args().size();
        if (kind == Kind.GROUP_CONCAT && c.distinct() && n == 2) {
            throw new SqlError("DISTINCT aggregates must have exactly one argument");
        }
        boolean ok = c.star() ? kind == Kind.COUNT : (n == 1 || (kind == Kind.GROUP_CONCAT && n == 2));
        if (!ok) throw new SqlError("wrong number of arguments to function " + c.name() + "()");
        Node arg = c.star() ? null : Binder.bind(c.args().get(0), scope);
        Node sep = n == 2 ? Binder.bind(c.args().get(1), scope) : null;
        List<Node> orderNodes = new ArrayList<>();
        List<Ordering.Key> order = new ArrayList<>();
        for (OrderTerm t : c.orderBy()) {
            orderNodes.add(Binder.bind(t.expr(), scope));
            order.add(Ordering.Key.of(t));
        }
        return new AggregateFunction(kind, c.distinct(), arg, sep, orderNodes, order);
    }

    boolean isExtreme() {
        return kind == Kind.MIN || kind == Kind.MAX;
    }

    Object compute(List<Object[]> rows) {
        if (arg == null) return (long) rows.size(); // count(*)
        rows = sortedByOrder(rows);
        Set<Object> seen = distinct ? new HashSet<>() : null;
        List<Object> values = new ArrayList<>();
        StringBuilder joined = new StringBuilder();
        for (Object[] row : rows) {
            Object v = arg.eval(row);
            if (v == null || (distinct && !seen.add(Values.groupKey(v)))) continue;
            if (kind == Kind.GROUP_CONCAT) {
                if (!values.isEmpty()) joined.append(separatorText(row));
                joined.append(Values.text(v));
            }
            values.add(v);
        }
        return switch (kind) {
            case COUNT -> (long) values.size();
            case MIN, MAX -> extreme(values);
            case GROUP_CONCAT -> values.isEmpty() ? null : joined.toString();
            default -> sum(values);
        };
    }

    private String separatorText(Object[] row) {
        if (separator == null) return ",";
        Object s = separator.eval(row);
        return s == null ? "" : Values.text(s);
    }

    private List<Object[]> sortedByOrder(List<Object[]> rows) {
        if (order.isEmpty()) return rows;
        List<Object[]> keyed = new ArrayList<>(); // {row, key values}
        for (Object[] row : rows) {
            Object[] ks = new Object[orderNodes.size()];
            for (int i = 0; i < ks.length; i++) ks[i] = orderNodes.get(i).eval(row);
            keyed.add(new Object[] {row, ks});
        }
        keyed.sort((a, b) -> Ordering.compare(order, (Object[]) a[1], (Object[]) b[1]));
        List<Object[]> sorted = new ArrayList<>();
        for (Object[] k : keyed) sorted.add((Object[]) k[0]);
        return sorted;
    }

    /** For min/max: the first row that gives the extreme non-NULL argument, or null if there is none. */
    Object[] extremeRow(List<Object[]> rows) {
        Object best = null;
        Object[] bestRow = null;
        for (Object[] row : rows) {
            Object v = arg.eval(row);
            if (v != null && (bestRow == null || better(v, best))) {
                best = v;
                bestRow = row;
            }
        }
        return bestRow;
    }

    private boolean better(Object candidate, Object best) {
        int c = Values.compare(candidate, best);
        return kind == Kind.MAX ? c > 0 : c < 0;
    }

    private Object extreme(List<Object> values) {
        Object best = null;
        for (Object v : values) {
            if (best == null || better(v, best)) best = v;
        }
        return best;
    }

    /** sum, total and avg (3.2 "Sums"): exact INTEGER sum while all values are INTEGER, then compensated REAL. */
    private Object sum(List<Object> values) {
        if (values.isEmpty()) return kind == Kind.TOTAL ? (Object) 0.0 : null;
        BigInteger intSum = BigInteger.ZERO;
        boolean real = false;
        double s = 0.0;
        double c = 0.0;
        for (Object v : values) {
            Long exact = asInteger(v);
            if (!real) {
                if (exact != null) {
                    intSum = intSum.add(BigInteger.valueOf(exact));
                    continue;
                }
                real = true;
                s = intSum.doubleValue();
            }
            double x = exact != null ? (double) exact : Values.toNumber(v).doubleValue();
            double t = s + x;
            c += Math.abs(s) > Math.abs(x) ? (s - t) + x : (x - t) + s;
            s = t;
        }
        if (!real) {
            if (kind == Kind.SUM) {
                if (intSum.bitLength() > 63) throw new SqlError("integer overflow");
                return intSum.longValue();
            }
            s = intSum.doubleValue();
            c = 0.0;
        }
        double total = s + c;
        return kind == Kind.AVG ? total / values.size() : (Object) total;
    }

    /** The INTEGER a value counts as in a sum: an INTEGER, or TEXT that is an integer literal; else null. */
    private static Long asInteger(Object v) {
        if (v instanceof Long l) return l;
        if (v instanceof String str && Values.parseNumericLiteral(str) instanceof Long l) return l;
        return null;
    }
}
