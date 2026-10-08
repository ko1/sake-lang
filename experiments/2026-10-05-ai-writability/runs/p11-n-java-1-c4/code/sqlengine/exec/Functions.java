package sqlengine.exec;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.Map;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;
import sqlengine.value.Values;

/** Scalar functions (1.11). Add new functions to the table in the static initialiser. */
final class Functions {
    private Functions() { }

    interface Fn {
        Object apply(Object[] args);
    }

    /** maxArgs < 0 means unbounded. nullIn: any NULL argument gives NULL without calling fn. */
    private record Def(int minArgs, int maxArgs, boolean nullIn, Fn fn) { }

    private static final Map<String, Def> DEFS = new HashMap<>();

    private static void def(String name, int min, int max, boolean nullIn, Fn fn) {
        DEFS.put(name, new Def(min, max, nullIn, fn));
    }

    static {
        def("length", 1, 1, true, a -> (long) Values.text(a[0]).codePointCount(0, Values.text(a[0]).length()));
        def("upper", 1, 1, true, a -> asciiCase(Values.text(a[0]), true));
        def("lower", 1, 1, true, a -> asciiCase(Values.text(a[0]), false));
        def("abs", 1, 1, true, Functions::abs);
        def("typeof", 1, 1, false, a -> Values.typeName(a[0]).toLowerCase(java.util.Locale.ROOT));
        def("coalesce", 2, -1, false, Functions::coalesce);
        def("ifnull", 2, 2, false, Functions::coalesce);
        def("nullif", 2, 2, false, a -> {
            if (a[0] == null || a[1] == null) return a[0];
            return Values.compare(a[0], a[1]) == 0 ? null : a[0];
        });
        def("substr", 2, 3, true, Functions::substr);
        def("trim", 1, 2, true, a -> trim(a, true, true));
        def("ltrim", 1, 2, true, a -> trim(a, true, false));
        def("rtrim", 1, 2, true, a -> trim(a, false, true));
        def("replace", 3, 3, true, Functions::replace);
        def("instr", 2, 2, true, a -> (long) (Values.text(a[0]).indexOf(Values.text(a[1])) + 1));
        def("round", 1, 2, true, Functions::round);
        def("max", 2, -1, true, a -> extreme(a, 1));
        def("min", 2, -1, true, a -> extreme(a, -1));
        // C.1: concat, concat_ws and char handle NULL themselves (nullIn=false).
        def("concat", 1, -1, false, a -> concat(a, 0, ""));
        def("concat_ws", 2, -1, false, a -> a[0] == null ? null : concat(a, 1, Values.text(a[0])));
        def("char", 0, -1, false, Functions::chars);
        def("unicode", 1, 1, true, a -> {
            String s = Values.text(a[0]);
            return s.isEmpty() ? null : (Object) (long) s.codePointAt(0);
        });
        def("sign", 1, 1, true, Functions::sign);
    }

    private static Object coalesce(Object[] a) {
        for (Object v : a) {
            if (v != null) return v;
        }
        return null;
    }

    /** Joins the text forms of a[from..] that are not NULL with sep; '' when all are NULL. */
    private static Object concat(Object[] a, int from, String sep) {
        StringBuilder sb = new StringBuilder();
        boolean first = true;
        for (int i = from; i < a.length; i++) {
            if (a[i] == null) continue;
            if (!first) sb.append(sep);
            sb.append(Values.text(a[i]));
            first = false;
        }
        return sb.toString();
    }

    private static Object chars(Object[] a) {
        StringBuilder sb = new StringBuilder();
        for (Object v : a) sb.appendCodePoint((int) toLong(v));
        return sb.toString();
    }

    /** sign(x): INTEGER -1/0/1; TEXT only when it is wholly a numeric literal (1.5 step 2), else NULL. */
    private static Object sign(Object[] a) {
        Number n = a[0] instanceof String s ? Values.parseNumericLiteral(s) : (Number) a[0];
        if (n == null) return null;
        if (n instanceof Long l) return (long) Long.signum(l);
        double d = n.doubleValue();
        return d < 0 ? -1L : (d > 0 ? 1L : 0L);
    }

    private static Object abs(Object[] a) {
        if (a[0] instanceof Long l) return Math.abs(l);
        if (a[0] instanceof Double d) return Math.abs(d);
        return Math.abs(Values.numericPrefix((String) a[0]).doubleValue());
    }

    /** substr per 2.4: p and q follow the specification's step-by-step adjustment. */
    private static Object substr(Object[] a) {
        String s = Values.text(a[0]);
        long len = s.length();
        long p = toLong(a[1]);
        long q = a.length > 2 ? toLong(a[2]) : Long.MAX_VALUE;
        if (p < 0) {
            p += len;
            if (p < 0) {
                q = a.length > 2 ? q + p : q;
                p = 0;
                if (q < 0) q = 0;
            }
        } else if (p > 0) {
            p -= 1;
        } else if (q > 0) {
            q -= 1;
        }
        if (q < 0) {
            q = -q;
            p -= q;
            if (p < 0) {
                q += p;
                p = 0;
            }
        }
        if (q <= 0 || p >= len) return "";
        long end = Math.min(len, p + Math.min(q, len));
        return s.substring((int) p, (int) end);
    }

    private static long toLong(Object v) {
        Number n = Values.toNumber(v);
        return n instanceof Long l ? l : (long) n.doubleValue();
    }

    private static Object trim(Object[] a, boolean left, boolean right) {
        String s = Values.text(a[0]);
        String chars = a.length > 1 ? Values.text(a[1]) : " ";
        int from = 0;
        int to = s.length();
        while (left && from < to && chars.indexOf(s.charAt(from)) >= 0) from++;
        while (right && to > from && chars.indexOf(s.charAt(to - 1)) >= 0) to--;
        return s.substring(from, to);
    }

    private static Object replace(Object[] a) {
        String s = Values.text(a[0]);
        String from = Values.text(a[1]);
        return from.isEmpty() ? s : s.replace(from, Values.text(a[2]));
    }

    /** round(x[, n]): half away from zero on the 17-significant-digit decimal form of x. */
    private static Object round(Object[] a) {
        Number x = Values.toNumber(a[0]);
        long digits = a.length > 1 ? Math.max(0, toLong(a[1])) : 0;
        if (x instanceof Long l) return (double) l;
        double d = x.doubleValue();
        BigDecimal exact = new BigDecimal(d).round(new MathContext(17, RoundingMode.HALF_EVEN));
        if (digits >= exact.scale()) return d;
        return exact.setScale((int) digits, RoundingMode.HALF_UP).doubleValue();
    }

    /** max (sign 1) or min (sign -1) in the order of values; the first of equal values wins. */
    private static Object extreme(Object[] a, int sign) {
        Object best = a[0];
        for (int i = 1; i < a.length; i++) {
            if (Values.compare(a[i], best) * sign > 0) best = a[i];
        }
        return best;
    }

    private static String asciiCase(String s, boolean up) {
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (up && c >= 'a' && c <= 'z') c -= 32;
            else if (!up && c >= 'A' && c <= 'Z') c += 32;
            sb.append(c);
        }
        return sb.toString();
    }

    /** Looks the function up at bind time (errors before any row is read) and returns its evaluator. */
    static Fn lookup(String name, int argc) {
        Def d = DEFS.get(Names.norm(name));
        if (d == null) throw new SqlError("no such function: " + name);
        if (argc < d.minArgs() || (d.maxArgs() >= 0 && argc > d.maxArgs())) {
            throw new SqlError("wrong number of arguments to function " + name + "()");
        }
        if (!d.nullIn()) return d.fn();
        return args -> {
            for (Object v : args) {
                if (v == null) return null;
            }
            return d.fn().apply(args);
        };
    }
}
