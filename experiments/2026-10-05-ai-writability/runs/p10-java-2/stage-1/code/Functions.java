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
}
