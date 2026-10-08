package sqlengine.value;

import sqlengine.parse.SqlError;

/** The collating sequences of 7.1: how two TEXT values compare. Only TEXT is affected, never the stored value. */
public enum Collation {
    BINARY, NOCASE, RTRIM;

    /** The collation called name (ASCII case-insensitive), or the "no such collation sequence" error. */
    public static Collation lookup(String name) {
        switch (Names.norm(name)) {
            case "binary": return BINARY;
            case "nocase": return NOCASE;
            case "rtrim": return RTRIM;
            default: throw new SqlError("no such collation sequence: " + name);
        }
    }

    /**
     * The collation of a comparison (7.4): an explicit one (left first), else an implicit one (left first), else
     * BINARY. Each argument is null when that operand has none of that kind.
     */
    public static Collation choose(Collation leftExplicit, Collation rightExplicit, Collation leftImplicit,
                                   Collation rightImplicit) {
        if (leftExplicit != null) return leftExplicit;
        if (rightExplicit != null) return rightExplicit;
        if (leftImplicit != null) return leftImplicit;
        return rightImplicit != null ? rightImplicit : BINARY;
    }

    /** A string equal to this collation's view of s: two strings are equal under it iff their folds are equal. */
    public String fold(String s) {
        switch (this) {
            case NOCASE:
                return Names.norm(s);
            case RTRIM: {
                int end = s.length();
                while (end > 0 && s.charAt(end - 1) == ' ') end--;
                return end == s.length() ? s : s.substring(0, end);
            }
            default:
                return s;
        }
    }

    /** fold for a TEXT value; any other value is returned as it is. */
    public Object foldValue(Object v) {
        return v instanceof String s ? fold(s) : v;
    }

    public int compare(String a, String b) {
        if (this == BINARY) return Integer.signum(a.compareTo(b));
        return Integer.signum(fold(a).compareTo(fold(b)));
    }
}
