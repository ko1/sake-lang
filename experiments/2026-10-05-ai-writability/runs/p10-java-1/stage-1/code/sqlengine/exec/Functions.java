package sqlengine.exec;

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
    }

    private static Object coalesce(Object[] a) {
        for (Object v : a) {
            if (v != null) return v;
        }
        return null;
    }

    private static Object abs(Object[] a) {
        if (a[0] instanceof Long l) return Math.abs(l);
        if (a[0] instanceof Double d) return Math.abs(d);
        return Math.abs(Values.numericPrefix((String) a[0]).doubleValue());
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
