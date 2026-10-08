package sqlengine.exec;

import sqlengine.value.Values;

/** Arithmetic and concatenation on runtime values (1.8). */
final class Operators {
    private Operators() { }

    static Object arith(String op, Object a, Object b) {
        if (a == null || b == null) return null;
        Number x = Values.toNumber(a);
        Number y = Values.toNumber(b);
        if (x instanceof Long p && y instanceof Long q) {
            switch (op) {
                case "+": return p + q;
                case "-": return p - q;
                case "*": return p * q;
                case "/": return q == 0 ? null : (Object) (p / q);
                default: return q == 0 ? null : (Object) (p % q);
            }
        }
        double u = x.doubleValue();
        double v = y.doubleValue();
        switch (op) {
            case "+": return u + v;
            case "-": return u - v;
            case "*": return u * v;
            case "/": return v == 0 ? null : (Object) (u / v);
            default: {
                long l = (long) u;
                long r = (long) v;
                return r == 0 ? null : (Object) (double) (l % r);
            }
        }
    }

    static Object negate(Object a) {
        if (a == null) return null;
        Number n = Values.toNumber(a);
        if (n instanceof Long l) return -l;
        return -n.doubleValue();
    }

    static Object concat(Object a, Object b) {
        if (a == null || b == null) return null;
        return Values.text(a) + Values.text(b);
    }
}
