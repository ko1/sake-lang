/** A collating sequence (CHANGE 7): how two TEXT values compare. Also finds the collation an expression carries. */
enum Collation {
    BINARY, NOCASE, RTRIM;

    /** The collation called name (case-insensitive), or the "no such collation sequence" error. */
    static Collation lookup(String name) {
        for (Collation c : values()) if (c.name().equalsIgnoreCase(name)) return c;
        throw new SqlError("no such collation sequence: " + name);
    }

    /** s in a form where two texts are equal under this collation exactly when their keys are equal. */
    String key(String s) {
        switch (this) {
            case NOCASE: {
                StringBuilder sb = null;
                for (int i = 0; i < s.length(); i++) {
                    char c = s.charAt(i);
                    if (c >= 'A' && c <= 'Z') {
                        if (sb == null) sb = new StringBuilder(s);
                        sb.setCharAt(i, (char) (c + 32));
                    }
                }
                return sb == null ? s : sb.toString();
            }
            case RTRIM: {
                int end = s.length();
                while (end > 0 && s.charAt(end - 1) == ' ') end--;
                return s.substring(0, end);
            }
            default:
                return s;
        }
    }

    int compare(String a, String b) {
        return Integer.signum(key(a).compareTo(key(b)));
    }

    // ---- the collation of an expression (7.3); e must be resolved ----

    /** The explicit collation (COLLATE) of e, or null. */
    static Collation explicitOf(Expr e) {
        if (e instanceof Expr.Collate c) return c.collation();
        if (e instanceof Expr.Unary u && u.op() == '+') return explicitOf(u.operand());
        if (e instanceof Expr.Cast c) return explicitOf(c.operand());
        return null;
    }

    /** The implicit collation (of a column) of e, or null. */
    static Collation implicitOf(Expr e) {
        if (e instanceof Expr.ColumnRef c) return c.collation();
        if (e instanceof Expr.Unary u && u.op() == '+') return implicitOf(u.operand());
        if (e instanceof Expr.Cast c) return implicitOf(c.operand());
        return null;
    }

    /** The collation for the values of the single expression e (7.4): explicit, else implicit, else BINARY. */
    static Collation of(Expr e) {
        return pick(explicitOf(e), null, implicitOf(e), null);
    }

    /** The collation of result column i of a plan: explicit, else implicit, else BINARY. */
    static Collation ofResult(QueryPlan p, int i) {
        return pick(p.explicitCollation(i), null, p.implicitCollation(i), null);
    }

    /** The collation of the comparison a op b (7.4). */
    static Collation forCompare(Expr a, Expr b) {
        return pick(explicitOf(a), explicitOf(b), implicitOf(a), implicitOf(b));
    }

    /** Explicit of a, else of b, else implicit of a, else of b, else BINARY. */
    static Collation pick(Collation explicitA, Collation explicitB, Collation implicitA, Collation implicitB) {
        if (explicitA != null) return explicitA;
        if (explicitB != null) return explicitB;
        if (implicitA != null) return implicitA;
        if (implicitB != null) return implicitB;
        return BINARY;
    }

    /** Per result column of a compound: the collation of the first part whose column has one, else BINARY. */
    static Collation[] ofCompound(java.util.List<? extends QueryPlan> parts) {
        int n = parts.get(0).columnCount();
        Collation[] out = new Collation[n];
        for (int k = 0; k < n; k++) {
            out[k] = BINARY;
            for (QueryPlan p : parts) {
                Collation c = pick(p.explicitCollation(k), null, p.implicitCollation(k), null);
                if (p.explicitCollation(k) != null || p.implicitCollation(k) != null) {
                    out[k] = c;
                    break;
                }
            }
        }
        return out;
    }
}
