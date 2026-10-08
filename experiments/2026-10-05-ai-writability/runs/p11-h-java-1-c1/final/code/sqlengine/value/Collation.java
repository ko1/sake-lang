package sqlengine.value;

/** Collating sequences (7.1): how two TEXT values compare. A null Collation in the API means BINARY. */
public enum Collation {
    BINARY, NOCASE, RTRIM;

    /** The collation with this name (case-insensitive), or null if there is none. */
    public static Collation named(String name) {
        switch (Names.norm(name)) {
            case "binary": return BINARY;
            case "nocase": return NOCASE;
            case "rtrim": return RTRIM;
            default: return null;
        }
    }

    /** The text as this collation compares it: equal keys exactly when the texts compare equal. */
    public String key(String s) {
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

    public int compare(String a, String b) {
        if (this == BINARY) return Integer.signum(a.compareTo(b));
        return Integer.signum(key(a).compareTo(key(b)));
    }
}
