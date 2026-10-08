import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Window functions, planning side (SPEC stage 6): the resolved call, the WINDOW clause of one simple select, and
 * the checks of names, argument counts and frames. Computing the values is WindowExec's job.
 */
final class Windows {
    private Windows() {}

    /** A resolved window call; name is lower case; args, partition and order terms are resolved. frame may be null. */
    record Call(String name, List<Expr> args, boolean star, List<Expr> partition, List<Stmt.OrderTerm> order,
                Stmt.Frame frame) {}

    /** The window calls of one simple select (each gets a slot, see Expr.WinRef) and its WINDOW clause. */
    static final class Collector {
        private final Map<String, Stmt.WindowSpec> named = new HashMap<>();
        private final List<Call> calls = new ArrayList<>();

        Collector(List<Stmt.NamedWindow> clause) {
            for (Stmt.NamedWindow w : clause) named.put(w.name().toLowerCase(Locale.ROOT), w.spec());
        }

        /** Slot of the call (an equal call already collected shares its slot). */
        int add(Call c) {
            int slot = calls.indexOf(c);
            if (slot < 0) {
                slot = calls.size();
                calls.add(c);
            }
            return slot;
        }

        List<Call> calls() {
            return calls;
        }

        /** The spec with its base window's parts filled in (what the spec does not have comes from the base). */
        Stmt.WindowSpec effective(Stmt.WindowSpec spec) {
            return effective(spec, new HashSet<>());
        }

        private Stmt.WindowSpec effective(Stmt.WindowSpec spec, Set<String> active) {
            if (spec.base() == null) return spec;
            String key = spec.base().toLowerCase(Locale.ROOT);
            Stmt.WindowSpec base = named.get(key);
            if (base == null) throw new SqlError("no such window: " + spec.base());
            if (!active.add(key)) throw new SqlError("circular reference: " + spec.base());
            Stmt.WindowSpec b = effective(base, active);
            active.remove(key);
            return new Stmt.WindowSpec(null, spec.partition().isEmpty() ? b.partition() : spec.partition(),
                spec.order().isEmpty() ? b.order() : spec.order(), spec.frame() != null ? spec.frame() : b.frame());
        }
    }

    private static final Map<String, int[]> WINDOW_ONLY = Map.of(
        "row_number", new int[] {0, 0}, "rank", new int[] {0, 0}, "dense_rank", new int[] {0, 0},
        "percent_rank", new int[] {0, 0}, "cume_dist", new int[] {0, 0}, "ntile", new int[] {1, 1},
        "lag", new int[] {1, 3}, "lead", new int[] {1, 3}, "first_value", new int[] {1, 1},
        "last_value", new int[] {1, 1});

    /** Names that are window functions only (nth_value too); the aggregates are not in this set. */
    static boolean isWindowOnly(String name) {
        String n = name.toLowerCase(Locale.ROOT);
        return WINDOW_ONLY.containsKey(n) || n.equals("nth_value");
    }

    static void checkArgs(String name, int argc) {
        int[] range = name.equals("nth_value") ? new int[] {2, 2} : WINDOW_ONLY.get(name);
        if (argc < range[0] || argc > range[1]) {
            throw new SqlError("wrong number of arguments to function " + name + "()");
        }
    }

    /** Rejects the frames SPEC 6.2 calls unsupported, and RANGE with an offset but not exactly one ORDER BY term. */
    static void checkFrame(Stmt.WindowSpec spec) {
        Stmt.Frame f = spec.frame();
        if (f == null) return;
        Stmt.BoundKind s = f.start().kind();
        Stmt.BoundKind e = f.end().kind();
        boolean startFollowing = s == Stmt.BoundKind.FOLLOWING || s == Stmt.BoundKind.UNBOUNDED_FOLLOWING;
        if ((s == Stmt.BoundKind.CURRENT_ROW && e == Stmt.BoundKind.PRECEDING)
            || (s == Stmt.BoundKind.FOLLOWING && (e == Stmt.BoundKind.CURRENT_ROW || e == Stmt.BoundKind.PRECEDING))
            || (startFollowing && e == Stmt.BoundKind.UNBOUNDED_PRECEDING)) {
            throw new SqlError("unsupported frame specification");
        }
        boolean offset = hasOffset(f.start()) || hasOffset(f.end());
        if (!f.rows() && offset && spec.order().size() != 1) {
            throw new SqlError("RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression");
        }
    }

    static boolean hasOffset(Stmt.Bound b) {
        return b.kind() == Stmt.BoundKind.PRECEDING || b.kind() == Stmt.BoundKind.FOLLOWING;
    }

    /** The rows with the value of each call appended: call k's value is at row[row.length - 1 - k]. */
    static List<Object[]> extend(List<Call> calls, List<Object[]> rows, Env outer) {
        if (calls.isEmpty()) return rows;
        int n = rows.size();
        List<Object[]> out = new ArrayList<>(n);
        for (Object[] row : rows) out.add(java.util.Arrays.copyOf(row, row.length + calls.size()));
        for (int k = 0; k < calls.size(); k++) {
            Object[] values = WindowExec.compute(calls.get(k), rows, outer);
            for (int r = 0; r < n; r++) {
                Object[] row = out.get(r);
                row[row.length - 1 - k] = values[r];
            }
        }
        return out;
    }
}
