import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/** The aggregate functions (SPEC 3.2): which calls are aggregates, argument checks, and computing one over a group. */
final class Aggregates {
    private Aggregates() {}

    /** A resolved aggregate call; args and order terms are resolved against the source row. name is lower case. */
    record Spec(String name, List<Expr> args, boolean star, boolean distinct, List<Stmt.OrderTerm> order) {}

    private static final Set<String> ALWAYS = Set.of("count", "sum", "total", "avg", "group_concat");

    /** True if the call is an aggregate: max/min with one argument, or any of the always-aggregate names. */
    static boolean isAggregate(Expr.Call c) {
        String n = c.name().toLowerCase(Locale.ROOT);
        if (n.equals("min") || n.equals("max")) return c.args().size() == 1 && !c.star();
        return ALWAYS.contains(n);
    }

    /** True if e contains an aggregate call (unresolved tree). */
    static boolean contains(Expr e) {
        if (e instanceof Expr.Call c && isAggregate(c)) return true;
        for (Expr child : Expr.children(e)) if (contains(child)) return true;
        return false;
    }

    /** Throws the error for a badly formed aggregate call (argument count, DISTINCT with two arguments). */
    static void check(Expr.Call c) {
        String n = c.name().toLowerCase(Locale.ROOT);
        int argc = c.args().size();
        if (n.equals("group_concat") && c.distinct() && argc == 2) {
            throw new SqlError("DISTINCT aggregates must have exactly one argument");
        }
        boolean ok;
        if (c.star()) ok = n.equals("count");
        else if (n.equals("group_concat")) ok = argc == 1 || argc == 2;
        else ok = argc == 1;
        if (!ok) throw new SqlError("wrong number of arguments to function " + c.name() + "()");
    }

    /** The value of the aggregate over the rows of one group. */
    static Object compute(Spec s, List<Object[]> rows, Env outer) {
        if (s.star()) return (long) rows.size();
        List<Object[]> ordered = s.order().isEmpty() ? rows : ordered(s, rows, outer);
        List<Object> values = new ArrayList<>();
        List<Object> seps = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        for (Object[] row : ordered) {
            Object v = Evaluator.eval(s.args().get(0), new Env(row, outer));
            if (v == null || (s.distinct() && !seen.add(Grouping.key(v)))) continue;
            values.add(v);
            if (s.args().size() > 1) seps.add(Evaluator.eval(s.args().get(1), new Env(row, outer)));
        }
        return switch (s.name()) {
            case "count" -> (long) values.size();
            case "sum" -> values.isEmpty() ? null : sum(values, false);
            case "total" -> sum(values, true);
            case "avg" -> values.isEmpty() ? null : (Object) (Values.toDouble(sum(values, true)) / values.size());
            case "min" -> extreme(values, -1);
            case "max" -> extreme(values, 1);
            default -> groupConcat(values, seps);
        };
    }

    /** The row of the group whose argument gives the min (sign -1) or max (sign 1); first row if all NULL. */
    static Object[] extremeRow(Spec s, List<Object[]> rows, int sign, Env outer) {
        Object[] best = rows.isEmpty() ? null : rows.get(0);
        Object bestValue = null;
        for (Object[] row : rows) {
            Object v = Evaluator.eval(s.args().get(0), new Env(row, outer));
            if (v != null && (bestValue == null || Values.compare(v, bestValue) * sign > 0)) {
                best = row;
                bestValue = v;
            }
        }
        return best;
    }

    private static List<Object[]> ordered(Spec s, List<Object[]> rows, Env outer) {
        List<Sorting.Term> terms = new ArrayList<>();
        for (Stmt.OrderTerm t : s.order()) terms.add(new Sorting.Term(t.desc(), t.nullsFirst()));
        List<Object[]> keyed = new ArrayList<>();
        for (Object[] row : rows) {
            Object[] entry = new Object[s.order().size() + 1];
            for (int i = 0; i < s.order().size(); i++) entry[i] = Evaluator.eval(s.order().get(i).expr(), new Env(row, outer));
            entry[s.order().size()] = row;
            keyed.add(entry);
        }
        keyed.sort((a, b) -> Sorting.compare(terms, a, b));
        List<Object[]> out = new ArrayList<>();
        for (Object[] entry : keyed) out.add((Object[]) entry[s.order().size()]);
        return out;
    }

    private static Object extreme(List<Object> values, int sign) {
        Object best = null;
        for (Object v : values) if (best == null || Values.compare(v, best) * sign > 0) best = v;
        return best;
    }

    private static Object groupConcat(List<Object> values, List<Object> seps) {
        if (values.isEmpty()) return null;
        StringBuilder sb = new StringBuilder(Values.textForm(values.get(0)));
        for (int i = 1; i < values.size(); i++) {
            Object sep = seps.isEmpty() ? "," : seps.get(i);
            if (sep != null) sb.append(Values.textForm(sep));
            sb.append(Values.textForm(values.get(i)));
        }
        return sb.toString();
    }

    /** SPEC 3.2 sums: a Long when every value is an INTEGER (and not forceReal), else the compensated REAL sum. */
    private static Object sum(List<Object> values, boolean forceReal) {
        int n = values.size();
        Object[] nums = new Object[n];
        boolean[] isInt = new boolean[n];
        int firstReal = n;
        for (int i = 0; i < n; i++) {
            Object v = values.get(i);
            if (v instanceof Blob b) {
                nums[i] = Values.numericPrefix(b.text());
            } else if (v instanceof String str) {
                Object p = Values.parseNumericText(str);
                nums[i] = p != null ? p : Values.numericPrefix(str);
                isInt[i] = p instanceof Long;
            } else {
                nums[i] = v;
                isInt[i] = v instanceof Long;
            }
            if (!isInt[i] && firstReal == n) firstReal = i;
        }
        long exact = 0;
        try {
            for (int i = 0; i < firstReal; i++) exact = Math.addExact(exact, (Long) nums[i]);
        } catch (ArithmeticException e) {
            throw new SqlError("integer overflow");
        }
        if (firstReal == n) return forceReal ? (Object) (double) exact : (Object) exact;
        double s = exact;
        double c = 0.0;
        for (int i = firstReal; i < n; i++) {
            double v = Values.toDouble(nums[i]);
            double t = s + v;
            if (Math.abs(s) > Math.abs(v)) c += (s - t) + v;
            else c += (v - t) + s;
            s = t;
        }
        return s + c;
    }
}
