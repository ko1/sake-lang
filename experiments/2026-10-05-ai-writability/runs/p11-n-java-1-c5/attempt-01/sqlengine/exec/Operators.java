package sqlengine.exec;

import sqlengine.parse.SqlError;
import sqlengine.value.SqlType;
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

    // ---- three-valued logic (1.10): results are 1, 0 or NULL ----
    static Object not(Object a) {
        Boolean t = Values.truth(a);
        return Values.fromBoolean(t == null ? null : !t);
    }

    static Object and(Object a, Object b) {
        Boolean x = Values.truth(a);
        Boolean y = Values.truth(b);
        if (Boolean.FALSE.equals(x) || Boolean.FALSE.equals(y)) return 0L;
        return x == null || y == null ? null : (Object) 1L;
    }

    static Object or(Object a, Object b) {
        Boolean x = Values.truth(a);
        Boolean y = Values.truth(b);
        if (Boolean.TRUE.equals(x) || Boolean.TRUE.equals(y)) return 1L;
        return x == null || y == null ? null : (Object) 0L;
    }

    // ---- comparison ----
    /** a op b with affinity (1.8, 1.9): NULL if either is NULL, else 1 or 0. op is = != < <= > >=. */
    static Object compare(String op, Object a, SqlType aAffinity, Object b, SqlType bAffinity) {
        if (a == null || b == null) return null;
        int c = Values.compareWithAffinity(a, aAffinity, b, bAffinity);
        boolean res = switch (op) {
            case "=" -> c == 0;
            case "!=" -> c != 0;
            case "<" -> c < 0;
            case "<=" -> c <= 0;
            case ">" -> c > 0;
            default -> c >= 0;
        };
        return res ? 1L : 0L;
    }

    /** x IN (items): 1 if some item equals x, else NULL if x or an item is NULL, else 0 (2.3). */
    static Object in(Object x, SqlType xAffinity, Object[] items) {
        return in(x, xAffinity, items, null);
    }

    /** As above, where each item has itemAffinity (a subquery's plain column, 4.3). */
    static Object in(Object x, SqlType xAffinity, Object[] items, SqlType itemAffinity) {
        if (x == null) return null;
        boolean sawNull = false;
        for (Object item : items) {
            if (item == null) {
                sawNull = true;
            } else if (Values.compareWithAffinity(x, xAffinity, item, itemAffinity) == 0) {
                return 1L;
            }
        }
        return sawNull ? null : (Object) 0L;
    }

    // ---- LIKE ----
    /** x LIKE p on text forms: % any run, _ any one character, others equal ignoring ASCII case. */
    static Object like(Object x, Object p) {
        if (x == null || p == null) return null;
        String s = Values.text(x);
        String pat = Values.text(p);
        int si = 0;
        int pi = 0;
        int star = -1;
        int mark = 0;
        while (si < s.length()) {
            if (pi < pat.length() && pat.charAt(pi) == '%') {
                star = pi++;
                mark = si;
            } else if (pi < pat.length() && (pat.charAt(pi) == '_' || foldCase(pat.charAt(pi)) == foldCase(s.charAt(si)))) {
                pi++;
                si++;
            } else if (star >= 0) {
                pi = star + 1;
                si = ++mark;
            } else {
                return 0L;
            }
        }
        while (pi < pat.length() && pat.charAt(pi) == '%') pi++;
        return pi == pat.length() ? 1L : 0L;
    }

    /** x LIKE p ESCAPE e: e must be one character (checked before NULLs); it makes the next pattern character ordinary. */
    static Object like(Object x, Object p, Object e) {
        String esc = null;
        if (e != null) {
            esc = Values.text(e);
            if (esc.codePointCount(0, esc.length()) != 1) throw new SqlError("ESCAPE expression must be a single character");
        }
        if (x == null || p == null || e == null) return null;
        String s = Values.text(x);
        String pat = Values.text(p);
        char ec = esc.charAt(0);
        // Tokens: a wildcard (-1 for %, -2 for _) or a literal char, so the matcher below stays the plain LIKE one.
        int[] toks = new int[pat.length()];
        int n = 0;
        for (int i = 0; i < pat.length(); i++) {
            char c = pat.charAt(i);
            if (c == ec) {
                if (i + 1 >= pat.length()) return 0L;
                toks[n++] = foldCase(pat.charAt(++i));
            } else if (c == '%') {
                toks[n++] = -1;
            } else if (c == '_') {
                toks[n++] = -2;
            } else {
                toks[n++] = foldCase(c);
            }
        }
        int si = 0;
        int pi = 0;
        int star = -1;
        int mark = 0;
        while (si < s.length()) {
            if (pi < n && toks[pi] == -1) {
                star = pi++;
                mark = si;
            } else if (pi < n && (toks[pi] == -2 || toks[pi] == foldCase(s.charAt(si)))) {
                pi++;
                si++;
            } else if (star >= 0) {
                pi = star + 1;
                si = ++mark;
            } else {
                return 0L;
            }
        }
        while (pi < n && toks[pi] == -1) pi++;
        return pi == n ? 1L : 0L;
    }

    /** x GLOB p on text forms: case-sensitive; * any run, ? one character, [..] / [^..] a class. */
    static Object glob(Object x, Object p) {
        if (x == null || p == null) return null;
        return globMatch(Values.text(x), Values.text(p)) ? 1L : 0L;
    }

    private static boolean globMatch(String s, String pat) {
        int si = 0;
        int pi = 0;
        int star = -1;
        int mark = 0;
        while (si < s.length()) {
            if (pi < pat.length() && pat.charAt(pi) == '*') {
                star = pi++;
                mark = si;
                continue;
            }
            boolean ok = false;
            int next = pi;
            if (pi < pat.length()) {
                char c = pat.charAt(pi);
                if (c == '?') {
                    ok = true;
                    next = pi + 1;
                } else if (c == '[') {
                    int end = classEnd(pat, pi);
                    if (end < 0) return false; // unclosed class matches nothing
                    ok = classMatches(pat, pi + 1, end, s.charAt(si));
                    next = end + 1;
                } else {
                    ok = c == s.charAt(si);
                    next = pi + 1;
                }
            }
            if (ok) {
                pi = next;
                si++;
            } else if (star >= 0) {
                pi = star + 1;
                si = ++mark;
            } else {
                return false;
            }
        }
        while (pi < pat.length() && pat.charAt(pi) == '*') pi++;
        return pi == pat.length();
    }

    /** Index of the ']' closing the class that opens at pat[open], or -1. A ']' right after '[' or '[^' is a member. */
    private static int classEnd(String pat, int open) {
        int i = open + 1;
        if (i < pat.length() && pat.charAt(i) == '^') i++;
        if (i < pat.length() && pat.charAt(i) == ']') i++;
        return pat.indexOf(']', i);
    }

    /** Whether ch is in the class whose body (after '[') is pat[from, end); a leading '^' negates. */
    private static boolean classMatches(String pat, int from, int end, char ch) {
        boolean negate = from < end && pat.charAt(from) == '^';
        int i = negate ? from + 1 : from;
        boolean in = false;
        while (i < end) {
            char lo = pat.charAt(i);
            if (i + 2 < end && pat.charAt(i + 1) == '-') { // x-y; a '-' right before the closing ']' is literal
                if (ch >= lo && ch <= pat.charAt(i + 2)) in = true;
                i += 3;
            } else {
                if (ch == lo) in = true;
                i++;
            }
        }
        return in != negate;
    }

    private static char foldCase(char c) {
        return c >= 'A' && c <= 'Z' ? (char) (c + 32) : c;
    }

    // ---- CAST (2.3) ----
    static Object cast(Object v, SqlType type) {
        if (v == null) return null;
        switch (type) {
            case INTEGER:
                if (v instanceof Long) return v;
                if (v instanceof Double d) return (long) (double) d; // truncates toward zero, saturates
                return Values.integerPrefix((String) v);
            case REAL:
                return Values.toNumber(v).doubleValue();
            default:
                return Values.text(v);
        }
    }
}
