import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Window functions, run time (SPEC 6.2, 6.3): partitions, peers, frames, and the value of a call on each row. */
final class WindowExec {
    private WindowExec() {}

    /** The value of the call for each of rows (same order as rows). */
    static Object[] compute(Windows.Call c, List<Object[]> rows, Env outer) {
        Object[] out = new Object[rows.size()];
        if (rows.isEmpty()) return out;
        checkOffsets(c.frame());
        Map<List<String>, List<Integer>> partitions = new LinkedHashMap<>();
        for (int r = 0; r < rows.size(); r++) {
            Env env = new Env(rows.get(r), outer);
            List<String> key = new ArrayList<>();
            for (Expr e : c.partition()) key.add(Grouping.key(Evaluator.eval(e, env)));
            partitions.computeIfAbsent(key, k -> new ArrayList<>()).add(r);
        }
        for (List<Integer> members : partitions.values()) new Partition(c, rows, members, outer).fill(out);
        return out;
    }

    private static void checkOffsets(Stmt.Frame f) {
        if (f == null) return;
        checkOffset(f.start(), f.rows(), "starting");
        checkOffset(f.end(), f.rows(), "ending");
    }

    private static void checkOffset(Stmt.Bound b, boolean rows, String which) {
        if (!Windows.hasOffset(b)) return;
        boolean ok = b.offset() instanceof Long k ? k >= 0 : (Double) b.offset() >= 0 && (!rows || isWhole((Double) b.offset()));
        if (!ok) {
            throw new SqlError("frame " + which + " offset must be a non-negative " + (rows ? "integer" : "number"));
        }
    }

    private static boolean isWhole(double d) {
        return d == Math.rint(d);
    }

    /** One partition: its rows in window order, with peer groups, and the evaluation of each function on it. */
    private static final class Partition {
        private final Windows.Call call;
        private final Env outer;
        private final int size;
        private final int[] origin;       // origin[i]: index in the caller's rows of the i-th row in window order
        private final Object[][] rows;    // the rows in window order
        private final Object[][] keys;    // ORDER BY values of each row
        private final int[] peerFirst;
        private final int[] peerLast;
        private final List<Sorting.Term> terms = new ArrayList<>();

        Partition(Windows.Call call, List<Object[]> all, List<Integer> members, Env outer) {
            this.call = call;
            this.outer = outer;
            for (Stmt.OrderTerm t : call.order()) terms.add(new Sorting.Term(t.desc(), t.nullsFirst()));
            size = members.size();
            Object[][] k = new Object[size][];
            for (int i = 0; i < size; i++) {
                Env env = new Env(all.get(members.get(i)), outer);
                k[i] = new Object[terms.size()];
                for (int t = 0; t < k[i].length; t++) k[i][t] = Evaluator.eval(call.order().get(t).expr(), env);
            }
            Integer[] positions = new Integer[size];
            for (int i = 0; i < size; i++) positions[i] = i;
            java.util.Arrays.sort(positions, (a, b) -> Sorting.compare(terms, k[a], k[b]));
            origin = new int[size];
            rows = new Object[size][];
            keys = new Object[size][];
            for (int i = 0; i < size; i++) {
                origin[i] = members.get(positions[i]);
                rows[i] = all.get(origin[i]);
                keys[i] = k[positions[i]];
            }
            peerFirst = new int[size];
            peerLast = new int[size];
            for (int i = 0; i < size; i++) peerFirst[i] = i > 0 && peers(i - 1, i) ? peerFirst[i - 1] : i;
            for (int i = size - 1; i >= 0; i--) peerLast[i] = i < size - 1 && peers(i, i + 1) ? peerLast[i + 1] : i;
        }

        private boolean peers(int a, int b) {
            return Sorting.compare(terms, keys[a], keys[b]) == 0;
        }

        void fill(Object[] out) {
            Aggregates.Spec agg = null;
            if (!Windows.isWindowOnly(call.name())) {
                agg = new Aggregates.Spec(call.name(), call.args(), call.star(), false, List.of());
            }
            int cacheLo = -1;
            int cacheHi = -2;
            Object cache = null;
            int dense = 0;
            for (int i = 0; i < size; i++) {
                if (peerFirst[i] == i) dense++;
                Env env = new Env(rows[i], outer);
                Object v;
                if (agg != null) {
                    int[] f = frame(i);
                    if (f[0] != cacheLo || f[1] != cacheHi) {
                        List<Object[]> in = new ArrayList<>();
                        for (int j = f[0]; j <= f[1]; j++) in.add(rows[j]);
                        cache = Aggregates.compute(agg, in, outer);
                        cacheLo = f[0];
                        cacheHi = f[1];
                    }
                    v = cache;
                } else {
                    v = function(i, env, dense);
                }
                out[origin[i]] = v;
            }
        }

        private Object function(int i, Env env, int dense) {
            switch (call.name()) {
                case "row_number": return (long) (i + 1);
                case "rank": return (long) (peerFirst[i] + 1);
                case "dense_rank": return (long) dense;
                case "percent_rank": return size == 1 ? 0.0 : (double) peerFirst[i] / (size - 1);
                case "cume_dist": return (double) (peerLast[i] + 1) / size;
                case "ntile": return ntile(i, env);
                case "lag": return shifted(i, env, -1);
                case "lead": return shifted(i, env, 1);
                default: return frameValue(i);
            }
        }

        private Object ntile(int i, Env env) {
            Object n = Evaluator.eval(call.args().get(0), env);
            Object num = n == null ? null : Values.toNumber(n);
            long buckets = num == null ? 0 : num instanceof Long l ? l : (long) (double) (Double) num;
            if (buckets <= 0) throw new SqlError("argument of ntile must be a positive integer");
            long q = size / buckets;
            long r = size % buckets;
            long big = r * (q + 1);
            return i < big ? i / (q + 1) + 1 : r + (i - big) / q + 1;
        }

        /** lag (direction -1) or lead (1): the argument on the row k places away, else the default. */
        private Object shifted(int i, Env env, int direction) {
            long k = 1;
            if (call.args().size() > 1) {
                Object kv = Evaluator.eval(call.args().get(1), env);
                if (kv == null) return null;
                Object num = Values.toNumber(kv);
                k = num instanceof Long l ? l : (long) (double) (Double) num;
            }
            long target = i + direction * k;
            if (target >= 0 && target < size) return Evaluator.eval(call.args().get(0), new Env(rows[(int) target], outer));
            return call.args().size() > 2 ? Evaluator.eval(call.args().get(2), env) : null;
        }

        /** first_value, last_value, nth_value: the argument on one row of the frame, NULL if there is none. */
        private Object frameValue(int i) {
            int[] f = frame(i);
            int lo = f[0];
            int hi = f[1];
            int target;
            switch (call.name()) {
                case "first_value" -> target = lo;
                case "last_value" -> target = hi;
                default -> {
                    Object nv = Evaluator.eval(call.args().get(1), new Env(rows[i], outer));
                    Object num = nv == null || nv instanceof String ? null : Values.toNumber(nv);
                    long n = num instanceof Long l ? l : num instanceof Double d && isWhole(d) ? (long) (double) d : 0;
                    if (n <= 0) throw new SqlError("second argument to nth_value must be a positive integer");
                    target = n > hi - lo + 1 ? -1 : (int) (lo + n - 1);
                }
            }
            if (lo > hi || target < 0) return null;
            return Evaluator.eval(call.args().get(0), new Env(rows[target], outer));
        }

        // ---- frames ----

        /** First and last row (window order, inclusive) of the frame of row i; first > last when it is empty. */
        private int[] frame(int i) {
            Stmt.Frame f = call.frame();
            if (f == null) return new int[] {0, peerLast[i]};
            int lo;
            int hi;
            if (f.rows()) {
                lo = rowsBound(f.start(), i);
                hi = rowsBound(f.end(), i);
            } else {
                lo = rangeBound(f.start(), i, true);
                hi = rangeBound(f.end(), i, false);
            }
            return new int[] {Math.max(lo, 0), Math.min(hi, size - 1)};
        }

        private int rowsBound(Stmt.Bound b, int i) {
            return switch (b.kind()) {
                case UNBOUNDED_PRECEDING -> 0;
                case UNBOUNDED_FOLLOWING -> size - 1;
                case CURRENT_ROW -> i;
                case PRECEDING -> (int) Math.max(i - ((Number) b.offset()).longValue(), -1);
                case FOLLOWING -> (int) Math.min(i + ((Number) b.offset()).longValue(), size);
            };
        }

        private int rangeBound(Stmt.Bound b, int i, boolean start) {
            switch (b.kind()) {
                case UNBOUNDED_PRECEDING: return 0;
                case UNBOUNDED_FOLLOWING: return size - 1;
                case CURRENT_ROW: return start ? peerFirst[i] : peerLast[i];
                default: break;
            }
            Object cur = keys[i][0];
            if (cur == null) return start ? peerFirst[i] : peerLast[i];
            boolean desc = call.order().get(0).desc();
            double offset = ((Number) b.offset()).doubleValue();
            double target = signed(cur, desc) + (b.kind() == Stmt.BoundKind.PRECEDING ? -offset : offset);
            if (start) {
                for (int j = 0; j < size; j++) if (compareKey(j, target) >= 0) return j;
                return size;
            }
            for (int j = size - 1; j >= 0; j--) if (compareKey(j, target) <= 0) return j;
            return -1;
        }

        /** The key in the space where the partition is sorted ascending. */
        private static double signed(Object v, boolean desc) {
            double d = Values.toDouble(Values.toNumber(v));
            return desc ? -d : d;
        }

        /** Row j's key against target (both in sorted space); a NULL key sorts before or after every number. */
        private int compareKey(int j, double target) {
            Object v = keys[j][0];
            Stmt.OrderTerm t = call.order().get(0);
            if (v == null) {
                boolean nullsFirst = t.nullsFirst() != null ? t.nullsFirst() : !t.desc();
                return nullsFirst ? -1 : 1;
            }
            return Double.compare(signed(v, t.desc()), target);
        }
    }
}
