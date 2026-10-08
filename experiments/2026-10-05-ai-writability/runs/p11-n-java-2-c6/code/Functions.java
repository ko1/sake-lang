import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/** The built-in scalar functions (SPEC 1.11). To add one, register it in the static block. */
final class Functions {
    private interface Impl {
        Object call(Object[] args);
    }

    /** max is -1 for "any number of arguments"; passesNull false means a NULL argument is handled by impl. */
    private record Def(int min, int max, boolean nullGivesNull, Impl impl) {}

    private static final Map<String, Def> REGISTRY = new HashMap<>();

    static {
        add("length", 1, 1, true, a -> (long) Values.textForm(a[0]).codePointCount(0, Values.textForm(a[0]).length()));
        add("upper", 1, 1, true, a -> asciiCase(Values.textForm(a[0]), true));
        add("lower", 1, 1, true, a -> asciiCase(Values.textForm(a[0]), false));
        add("abs", 1, 1, true, Functions::abs);
        add("typeof", 1, 1, false, a -> a[0] == null ? "null" : Values.typeName(a[0]).toLowerCase(Locale.ROOT));
        add("coalesce", 2, -1, false, Functions::coalesce);
        add("ifnull", 2, 2, false, Functions::coalesce);
        add("substr", 2, 3, true, Functions::substr);
        add("trim", 1, 2, true, a -> trim(a, true, true));
        add("ltrim", 1, 2, true, a -> trim(a, true, false));
        add("rtrim", 1, 2, true, a -> trim(a, false, true));
        add("replace", 3, 3, true, Functions::replace);
        add("instr", 2, 2, true, a -> (long) Values.textForm(a[0]).indexOf(Values.textForm(a[1])) + 1);
        add("round", 1, 2, true, Functions::round);
        add("max", 2, -1, true, a -> extreme(a, 1));
        add("min", 2, -1, true, a -> extreme(a, -1));
        add("ceil", 1, 1, true, a -> roundWhole(a[0], Math::ceil));
        add("ceiling", 1, 1, true, a -> roundWhole(a[0], Math::ceil));
        add("floor", 1, 1, true, a -> roundWhole(a[0], Math::floor));
        add("trunc", 1, 1, true, a -> roundWhole(a[0], x -> x < 0 ? Math.ceil(x) : Math.floor(x)));
        add("mod", 2, 2, true, Functions::mod);
        add("pow", 2, 2, true, Functions::pow);
        add("power", 2, 2, true, Functions::pow);
        add("sqrt", 1, 1, true, Functions::sqrt);
        add("pi", 0, 0, true, a -> Math.PI);
        add("nullif", 2, 2, false, a -> a[0] != null && a[1] != null && Values.compare(a[0], a[1]) == 0 ? null : a[0]);
    }

    private Functions() {}

    private static void add(String name, int min, int max, boolean nullGivesNull, Impl impl) {
        REGISTRY.put(name, new Def(min, max, nullGivesNull, impl));
    }

    /** Throws the "no such function" or "wrong number of arguments" error for a bad call. */
    static void check(String name, int argc) {
        Def d = REGISTRY.get(name.toLowerCase(Locale.ROOT));
        if (d == null) throw new SqlError("no such function: " + name);
        if (argc < d.min || (d.max >= 0 && argc > d.max)) {
            throw new SqlError("wrong number of arguments to function " + name + "()");
        }
    }

    static Object call(String name, Object[] args) {
        Def d = REGISTRY.get(name.toLowerCase(Locale.ROOT));
        if (d.nullGivesNull) {
            for (Object a : args) if (a == null) return null;
        }
        return d.impl.call(args);
    }

    private static Object abs(Object[] a) {
        Object n = Values.toNumber(a[0]);
        if (a[0] instanceof String) return Math.abs(Values.toDouble(n));
        return n instanceof Long l ? (Object) Math.abs(l) : (Object) Math.abs((Double) n);
    }

    /** SPEC 7.1: a Long or Double for the argument, or null (the call gives NULL) for text that is not a numeric literal. */
    private static Object mathArg(Object v) {
        return v instanceof String s ? Values.parseNumericText(s) : v;
    }

    /** SPEC 7.2 ceil/floor/trunc: an INTEGER is kept, a REAL is rounded by op and stays a REAL. */
    private static Object roundWhole(Object arg, java.util.function.DoubleUnaryOperator op) {
        Object n = mathArg(arg);
        if (n == null || n instanceof Long) return n;
        return op.applyAsDouble((Double) n);
    }

    /** SPEC 7.2 mod: C's fmod on both as REAL; NULL when y is zero. */
    private static Object mod(Object[] a) {
        Object x = mathArg(a[0]);
        Object y = mathArg(a[1]);
        if (x == null || y == null) return null;
        double dy = Values.toDouble(y);
        if (dy == 0) return null;
        return Values.toDouble(x) % dy;
    }

    /** SPEC 7.2 pow: NULL when the result is not a real number. */
    private static Object pow(Object[] a) {
        Object x = mathArg(a[0]);
        Object y = mathArg(a[1]);
        if (x == null || y == null) return null;
        double r = Math.pow(Values.toDouble(x), Values.toDouble(y));
        return Double.isNaN(r) ? null : (Object) r;
    }

    /** SPEC 7.2 sqrt: NULL for a negative x. */
    private static Object sqrt(Object[] a) {
        Object x = mathArg(a[0]);
        if (x == null) return null;
        double d = Values.toDouble(x);
        return d < 0 ? null : (Object) Math.sqrt(d);
    }

    private static Object coalesce(Object[] a) {
        for (Object v : a) if (v != null) return v;
        return null;
    }

    private static String asciiCase(String s, boolean upper) {
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (upper && c >= 'a' && c <= 'z') c -= 32;
            else if (!upper && c >= 'A' && c <= 'Z') c += 32;
            sb.append(c);
        }
        return sb.toString();
    }

    /** SPEC 2.4 substr, positions counted in characters. */
    private static Object substr(Object[] a) {
        String s = Values.textForm(a[0]);
        long p = integer(a[1]);
        long q = a.length > 2 ? integer(a[2]) : Long.MAX_VALUE;
        if (p < 0) {
            p += s.length();
            if (p < 0) {
                q += p;
                p = 0;
                if (q < 0) q = 0;
            }
        } else if (p > 0) {
            p--;
        } else if (q > 0) {
            q--;
        }
        if (q < 0) {
            q = -q;
            p -= q;
            if (p < 0) {
                q += p;
                p = 0;
            }
        }
        long from = Math.min(p, s.length());
        long to = q <= 0 ? from : Math.min(s.length(), p + Math.min(q, Long.MAX_VALUE - p));
        return s.substring((int) from, (int) Math.max(from, to));
    }

    private static long integer(Object v) {
        Object n = Values.toNumber(v);
        return n instanceof Long l ? l : (long) (double) (Double) n;
    }

    private static Object trim(Object[] a, boolean left, boolean right) {
        String s = Values.textForm(a[0]);
        String chars = a.length > 1 ? Values.textForm(a[1]) : " ";
        int from = 0;
        int to = s.length();
        if (left) while (from < to && chars.indexOf(s.charAt(from)) >= 0) from++;
        if (right) while (to > from && chars.indexOf(s.charAt(to - 1)) >= 0) to--;
        return s.substring(from, to);
    }

    private static Object replace(Object[] a) {
        String s = Values.textForm(a[0]);
        String from = Values.textForm(a[1]);
        return from.isEmpty() ? s : s.replace(from, Values.textForm(a[2]));
    }

    /** Rounds the 17-significant-digit decimal form of x, halves away from zero. */
    private static Object round(Object[] a) {
        double x = Values.toDouble(Values.toNumber(a[0]));
        long n = a.length > 1 ? Math.max(0, integer(a[1])) : 0;
        if (Double.isNaN(x) || Double.isInfinite(x)) return x;
        BigDecimal d = new BigDecimal(x).round(new MathContext(17, RoundingMode.HALF_EVEN));
        return d.setScale((int) Math.min(n, 400), RoundingMode.HALF_UP).doubleValue();
    }

    /** max (sign 1) or min (sign -1) in the order of values; the first of equal values wins. */
    private static Object extreme(Object[] a, int sign) {
        Object best = a[0];
        for (int i = 1; i < a.length; i++) {
            if (Values.compare(a[i], best) * sign > 0) best = a[i];
        }
        return best;
    }
}
