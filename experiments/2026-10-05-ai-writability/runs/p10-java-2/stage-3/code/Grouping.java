import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * GROUP BY (SPEC 3.3). Turns the filtered source rows into group rows: each is the columns of one
 * representative source row (the "bare column" values) followed by one slot per aggregate Spec,
 * the layout that Expr.AggRef indexes into.
 */
final class Grouping {
    private Grouping() {}

    /** Equality key of a value under the order of values (1.9): NULLs equal, 1 equals 1.0. */
    static String key(Object v) {
        if (v == null) return "N";
        if (v instanceof String s) return "t" + s;
        if (v instanceof Double d && d == Math.rint(d) && Math.abs(d) < 9.0e18) return "n" + (long) (double) d;
        return (v instanceof Long ? "n" : "d") + v;
    }

    static List<Object[]> groups(List<Object[]> rows, List<Expr> groupBy, List<Aggregates.Spec> specs, int ncols) {
        Map<List<String>, List<Object[]>> groups = new LinkedHashMap<>();
        if (groupBy.isEmpty()) {
            groups.put(List.of(), rows);
        } else {
            for (Object[] row : rows) {
                List<String> k = new ArrayList<>();
                for (Expr e : groupBy) k.add(key(Evaluator.eval(e, row)));
                groups.computeIfAbsent(k, x -> new ArrayList<>()).add(row);
            }
        }
        List<Object[]> out = new ArrayList<>();
        for (List<Object[]> group : groups.values()) out.add(groupRow(group, specs, ncols));
        return out;
    }

    private static Object[] groupRow(List<Object[]> group, List<Aggregates.Spec> specs, int ncols) {
        Object[] result = new Object[ncols + specs.size()];
        Object[] representative = group.isEmpty() ? null : group.get(0);
        if (specs.size() == 1 && specs.get(0).args().size() == 1 && !specs.get(0).star()) {
            Aggregates.Spec s = specs.get(0);
            if (s.name().equals("min")) representative = Aggregates.extremeRow(s, group, -1);
            else if (s.name().equals("max")) representative = Aggregates.extremeRow(s, group, 1);
        }
        if (representative != null) System.arraycopy(representative, 0, result, 0, ncols);
        for (int i = 0; i < specs.size(); i++) result[ncols + i] = Aggregates.compute(specs.get(i), group);
        return result;
    }
}
