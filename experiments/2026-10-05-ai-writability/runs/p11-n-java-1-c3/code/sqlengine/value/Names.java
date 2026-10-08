package sqlengine.value;

/** Identifier comparison: ASCII case-insensitive. */
public final class Names {
    private Names() { }

    public static String norm(String s) {
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

    /** True for the three reserved rowid names (7.1), in any case. */
    public static boolean isRowid(String s) {
        String n = norm(s);
        return n.equals("rowid") || n.equals("_rowid_") || n.equals("oid");
    }

    public static boolean same(String a, String b) {
        return norm(a).equals(norm(b));
    }
}
