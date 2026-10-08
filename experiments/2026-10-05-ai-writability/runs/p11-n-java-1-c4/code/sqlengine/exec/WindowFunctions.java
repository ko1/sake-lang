package sqlengine.exec;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.Call;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;
import sqlengine.value.Values;

/** The functions usable with OVER (6.3): the aggregates over the frame, and the window-only functions. */
final class WindowFunctions {
    private WindowFunctions() { }

    private record Arity(int min, int max) { }

    private static final Map<String, Arity> WINDOW_ONLY = new HashMap<>();

    static {
        for (String n : List.of("row_number", "rank", "dense_rank", "percent_rank", "cume_dist")) {
            WINDOW_ONLY.put(n, new Arity(0, 0));
        }
        WINDOW_ONLY.put("ntile", new Arity(1, 1));
        WINDOW_ONLY.put("lag", new Arity(1, 3));
        WINDOW_ONLY.put("lead", new Arity(1, 3));
        WINDOW_ONLY.put("first_value", new Arity(1, 1));
        WINDOW_ONLY.put("last_value", new Arity(1, 1));
        WINDOW_ONLY.put("nth_value", new Arity(2, 2));
    }

    /** True for the names that are window functions and nothing else (calling one without OVER is misuse). */
    static boolean isWindowOnly(String name) {
        return WINDOW_ONLY.containsKey(Names.norm(name));
    }

    /** Binds the call written before OVER; its arguments are bound in scope. */
    static WindowFunction bind(Call c, Scope scope) {
        String name = Names.norm(c.name());
        if (Aggregates.isAggregate(c)) {
            if (c.distinct()) throw new SqlError("DISTINCT is not supported for window functions");
            if (!c.orderBy().isEmpty()) throw SqlError.syntax();
            return overFrame(AggregateFunction.bind(c, scope));
        }
        Arity arity = WINDOW_ONLY.get(name);
        if (arity == null) throw new SqlError(c.name() + "() may not be used as a window function");
        int n = c.args().size();
        if (c.star() || n < arity.min() || n > arity.max()) {
            throw new SqlError("wrong number of arguments to function " + c.name() + "()");
        }
        Node[] a = c.args().stream().map(e -> Binder.bind(e, scope)).toArray(Node[]::new);
        return switch (name) {
            case "row_number" -> (p, f, out) -> each(p, i -> (long) (i + 1), out);
            case "rank" -> (p, f, out) -> each(p, i -> (long) (p.peerStart[i] + 1), out);
            case "dense_rank" -> WindowFunctions::denseRank;
            case "percent_rank" -> (p, f, out) ->
                each(p, i -> p.size() == 1 ? 0.0 : (double) p.peerStart[i] / (p.size() - 1), out);
            case "cume_dist" -> (p, f, out) -> each(p, i -> (double) p.peerEnd[i] / p.size(), out);
            case "ntile" -> (p, f, out) -> ntile(p, a[0], out);
            case "lag" -> (p, f, out) -> shifted(p, a, -1, out);
            case "lead" -> (p, f, out) -> shifted(p, a, 1, out);
            case "first_value" -> (p, f, out) -> each(p, i -> {
                int lo = f.first(p, i);
                return lo < f.after(p, i) ? a[0].eval(p.rows.get(lo)) : null;
            }, out);
            case "last_value" -> (p, f, out) -> each(p, i -> {
                int hi = f.after(p, i);
                return f.first(p, i) < hi ? a[0].eval(p.rows.get(hi - 1)) : null;
            }, out);
            default -> (p, f, out) -> nthValue(p, f, a, out);
        };
    }

    private interface PerRow {
        Object at(int pos);
    }

    private static void each(Partition p, PerRow fn, Object[] out) {
        for (int i = 0; i < p.size(); i++) out[i] = fn.at(i);
    }

    /** An aggregate (3.2) computed over each row's frame; neighbouring rows often share a frame. */
    private static WindowFunction overFrame(AggregateFunction agg) {
        return (p, f, out) -> {
            int prevLo = -1;
            int prevHi = -1;
            Object prev = null;
            for (int i = 0; i < p.size(); i++) {
                int lo = f.first(p, i);
                int hi = Math.max(lo, f.after(p, i));
                if (i == 0 || lo != prevLo || hi != prevHi) {
                    prev = agg.compute(p.rows.subList(Math.min(lo, p.size()), Math.min(hi, p.size())));
                    prevLo = lo;
                    prevHi = hi;
                }
                out[i] = prev;
            }
        };
    }

    private static void denseRank(Partition p, WindowFrame f, Object[] out) {
        long groups = 0;
        for (int i = 0; i < p.size(); i++) {
            if (p.peerStart[i] == i) groups++;
            out[i] = groups;
        }
    }

    /** n buckets, the first (size mod n) of them one row larger. */
    private static void ntile(Partition p, Node arg, Object[] out) {
        for (int i = 0; i < p.size(); i++) {
            Object v = arg.eval(p.rows.get(i));
            long buckets = v == null ? 0 : integer(v);
            if (buckets <= 0) throw new SqlError("argument of ntile must be a positive integer");
            long size = p.size() / buckets;
            long larger = p.size() % buckets;
            long cut = larger * (size + 1); // rows held by the larger buckets
            out[i] = i < cut ? i / (size + 1) + 1 : larger + (i - cut) / size + 1;
        }
    }

    /** lag (direction -1) and lead (+1): arguments x, offset (default 1), default value (default NULL). */
    private static void shifted(Partition p, Node[] a, int direction, Object[] out) {
        for (int i = 0; i < p.size(); i++) {
            Object[] row = p.rows.get(i);
            long k = 1;
            if (a.length > 1) {
                Object kv = a[1].eval(row);
                if (kv == null) {
                    out[i] = null;
                    continue;
                }
                k = integer(kv);
            }
            long target = i + direction * k;
            if (target >= 0 && target < p.size()) out[i] = a[0].eval(p.rows.get((int) target));
            else out[i] = a.length > 2 ? a[2].eval(row) : null;
        }
    }

    private static void nthValue(Partition p, WindowFrame f, Node[] a, Object[] out) {
        for (int i = 0; i < p.size(); i++) {
            Object nv = a[1].eval(p.rows.get(i));
            if (!(nv instanceof Long || nv instanceof Double d && d == Math.floor(d) && !Double.isInfinite(d))
                || integer(nv) < 1) {
                throw new SqlError("second argument to nth_value must be a positive integer");
            }
            int lo = f.first(p, i);
            long idx = lo + integer(nv) - 1;
            out[i] = idx < f.after(p, i) ? a[0].eval(p.rows.get((int) idx)) : null;
        }
    }

    private static long integer(Object v) {
        Number n = Values.toNumber(v);
        return n instanceof Long l ? l : (long) n.doubleValue();
    }
}
