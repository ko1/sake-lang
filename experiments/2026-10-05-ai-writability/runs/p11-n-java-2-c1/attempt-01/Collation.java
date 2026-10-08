import java.util.Locale;

/**
 * A collating sequence (SPEC 7): how two TEXT values compare. Also finds the collation an expression has
 * (7.3) and the one a comparison uses (7.4). Everything here that takes an Expr expects a resolved one.
 */
enum Collation {
    BINARY, NOCASE, RTRIM;

    /** The collation called name (any case), or the "no such collation sequence" error spelled as written. */
    static Collation parse(String name) {
        return switch (name.toUpperCase(Locale.ROOT)) {
            case "BINARY" -> BINARY;
            case "NOCASE" -> NOCASE;
            case "RTRIM" -> RTRIM;
            default -> throw new SqlError("no such collation sequence: " + name);
        };
    }

    /** Order of two TEXT values under this collation: -1, 0 or 1. */
    int compare(String a, String b) {
        int la = a.length();
        int lb = b.length();
        if (this == RTRIM) {
            la = trimmedLength(a);
            lb = trimmedLength(b);
        }
        boolean fold = this == NOCASE;
        int n = Math.min(la, lb);
        for (int i = 0; i < n; i++) {
            char x = a.charAt(i);
            char y = b.charAt(i);
            if (fold) {
                x = lower(x);
                y = lower(y);
            }
            if (x != y) return x < y ? -1 : 1;
        }
        return Integer.compare(la, lb);
    }

    /** A string that is equal for exactly the TEXT values this collation calls equal (for hashing). */
    String key(String s) {
        return switch (this) {
            case BINARY -> s;
            case NOCASE -> {
                StringBuilder sb = new StringBuilder(s.length());
                for (int i = 0; i < s.length(); i++) sb.append(lower(s.charAt(i)));
                yield sb.toString();
            }
            case RTRIM -> s.substring(0, trimmedLength(s));
        };
    }

    private static char lower(char c) {
        return c >= 'A' && c <= 'Z' ? (char) (c + 32) : c;
    }

    private static int trimmedLength(String s) {
        int n = s.length();
        while (n > 0 && s.charAt(n - 1) == ' ') n--;
        return n;
    }

    // ---- the collation of an expression (7.3) ----

    /** The collation e names with COLLATE (through parentheses, unary + and CAST), or null. */
    static Collation explicit(Expr e) {
        if (e instanceof Expr.Collate c) return c.collation();
        if (e instanceof Expr.Unary u && u.op() == '+') return explicit(u.operand());
        if (e instanceof Expr.Cast c) return explicit(c.operand());
        return null;
    }

    /** The collation e gets from a column (through unary + and CAST), or null. */
    static Collation implicit(Expr e) {
        if (e instanceof Expr.ColumnRef c) return c.collation();
        if (e instanceof Expr.Unary u && u.op() == '+') return implicit(u.operand());
        if (e instanceof Expr.Cast c) return implicit(c.operand());
        return null;
    }

    /** The explicit collation of e, else its implicit one, else null. */
    static Collation find(Expr e) {
        Collation c = explicit(e);
        return c != null ? c : implicit(e);
    }

    /** The collation an ordering, grouping or IN term e sorts and compares under: find(e), else BINARY. */
    static Collation of(Expr e) {
        Collation c = find(e);
        return c != null ? c : BINARY;
    }

    /** The collation of the comparison a op b (SPEC 7.4): explicit left, explicit right, implicit left, implicit right. */
    static Collation forComparison(Expr a, Expr b) {
        return choose(explicit(a), implicit(a), explicit(b), implicit(b));
    }

    /** The same rule, for operands given as their explicit and implicit collations (each may be null). */
    static Collation choose(Collation explicitLeft, Collation implicitLeft, Collation explicitRight,
                            Collation implicitRight) {
        if (explicitLeft != null) return explicitLeft;
        if (explicitRight != null) return explicitRight;
        if (implicitLeft != null) return implicitLeft;
        if (implicitRight != null) return implicitRight;
        return BINARY;
    }
}
