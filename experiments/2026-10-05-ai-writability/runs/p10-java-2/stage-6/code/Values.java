/**
 * Runtime values and their rules. A value is null (NULL), Long (INTEGER), Double (REAL) or String (TEXT).
 * Holds type names, text form, numeric parsing, storing into columns, the order of values and affinity.
 */
final class Values {
    private Values() {}

    static String typeName(Object v) {
        if (v == null) return "NULL";
        if (v instanceof Long) return "INTEGER";
        if (v instanceof Double) return "REAL";
        return "TEXT";
    }

    /** The text form of a non-NULL value (SPEC 1.3). */
    static String textForm(Object v) {
        if (v instanceof Long l) return Long.toString(l);
        if (v instanceof Double d) return RealFormat.format(d);
        return (String) v;
    }

    /** Printed form of any value in a result row. */
    static String display(Object v) {
        return v == null ? "NULL" : textForm(v);
    }

    // ---- numeric text ----

    private static boolean isSpace(char c) {
        return c == ' ' || c == '\t' || c == '\n' || c == '\r';
    }

    private static boolean isDigit(char c) {
        return c >= '0' && c <= '9';
    }

    /** End index of the unsigned numeric literal starting at i (digits, fraction, exponent), or i if none. */
    static int scanNumber(String s, int i) {
        int n = s.length();
        int j = i;
        int mant = 0;
        while (j < n && isDigit(s.charAt(j))) { j++; mant++; }
        if (j < n && s.charAt(j) == '.') {
            int k = j + 1;
            int frac = 0;
            while (k < n && isDigit(s.charAt(k))) { k++; frac++; }
            if (mant + frac > 0) { j = k; mant += frac; }
        }
        if (mant == 0) return i;
        if (j < n && (s.charAt(j) == 'e' || s.charAt(j) == 'E')) {
            int k = j + 1;
            if (k < n && (s.charAt(k) == '+' || s.charAt(k) == '-')) k++;
            int e = k;
            while (k < n && isDigit(s.charAt(k))) k++;
            if (k > e) j = k;
        }
        return j;
    }

    /** Long or Double for text that is a numeric literal (no sign); an integer out of range becomes a Double. */
    static Object parseNumber(String text) {
        boolean real = false;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (!isDigit(c) && c != '+' && c != '-') { real = true; break; }
        }
        if (!real) {
            try {
                return Long.parseLong(text);
            } catch (NumberFormatException e) {
                // falls through to double
            }
        }
        return Double.parseDouble(text);
    }

    /** The number (Long or Double) for text that is entirely a numeric literal after trimming, else null. */
    static Object parseNumericText(String s) {
        int a = 0;
        int b = s.length();
        while (a < b && isSpace(s.charAt(a))) a++;
        while (b > a && isSpace(s.charAt(b - 1))) b--;
        if (a == b) return null;
        int i = a;
        if (s.charAt(i) == '+' || s.charAt(i) == '-') i++;
        int end = scanNumber(s, i);
        if (end == i || end != b) return null;
        Object v = parseNumber(s.substring(i, end));
        return s.charAt(a) == '-' ? negate(v) : v;
    }

    /** Numeric-prefix reading of a TEXT value (SPEC 1.8): a Long or Double, INTEGER 0 if no prefix. */
    static Object numericPrefix(String s) {
        int n = s.length();
        int i = 0;
        while (i < n && isSpace(s.charAt(i))) i++;
        int sign = i;
        if (i < n && (s.charAt(i) == '+' || s.charAt(i) == '-')) i++;
        int end = scanNumber(s, i);
        if (end == i) return 0L;
        Object v = parseNumber(s.substring(i, end));
        return s.charAt(sign) == '-' ? negate(v) : v;
    }

    private static Object negate(Object v) {
        return v instanceof Long l ? (Object) (-l) : (Object) (-(Double) v);
    }

    /** A non-NULL value read as a number: Long or Double. */
    static Object toNumber(Object v) {
        return v instanceof String s ? numericPrefix(s) : v;
    }

    static double toDouble(Object number) {
        return number instanceof Long l ? (double) l : (Double) number;
    }

    // ---- truth ----

    /** Truth value of a condition (SPEC 1.10): TRUE, FALSE, or null for unknown. */
    static Boolean truth(Object v) {
        if (v == null) return null;
        Object n = toNumber(v);
        return n instanceof Long l ? l != 0 : (Double) n != 0.0;
    }

    static Object fromTruth(Boolean b) {
        return b == null ? null : (b ? 1L : 0L);
    }

    // ---- storing into a column ----

    /** Converts v for storage in a column of the given type, or throws the rejection error (SPEC 1.5). */
    static Object store(Object v, ColType type, String table, String column) {
        if (v == null) return null;
        if (v instanceof String s && type.isNumeric()) {
            Object n = parseNumericText(s);
            if (n != null) v = n;
        }
        switch (type) {
            case INTEGER:
                if (v instanceof Long) return v;
                if (v instanceof Double d && d == Math.rint(d) && d >= -0x1p63 && d < 0x1p63) return (long) (double) d;
                break;
            case REAL:
                if (v instanceof Long l) return (double) l;
                if (v instanceof Double) return v;
                break;
            default:
                return textForm(v);
        }
        throw new SqlError("cannot store " + typeName(v) + " value in " + type + " column " + table + "." + column);
    }

    // ---- order of values, affinity ----

    /** Total order of values: NULL < numbers < TEXT. */
    static int compare(Object a, Object b) {
        if (a == null || b == null) return a == null ? (b == null ? 0 : -1) : 1;
        boolean ta = a instanceof String;
        boolean tb = b instanceof String;
        if (ta || tb) {
            if (ta && tb) return Integer.signum(((String) a).compareTo((String) b));
            return ta ? 1 : -1;
        }
        if (a instanceof Long x && b instanceof Long y) return Long.compare(x, y);
        if (a instanceof Double x && b instanceof Double y) return Double.compare(x == 0 ? 0.0 : x, y == 0 ? 0.0 : y);
        if (a instanceof Long x) return -compareDoubleLong((Double) b, x);
        return compareDoubleLong((Double) a, (Long) b);
    }

    private static int compareDoubleLong(double d, long l) {
        if (d >= 0x1p63) return 1;
        if (d < -0x1p63) return -1;
        long dl = (long) d;
        if (dl != l) return dl < l ? -1 : 1;
        double frac = d - dl;
        return frac > 0 ? 1 : frac < 0 ? -1 : 0;
    }

    /** Affinity of an expression: its column's type for a column reference or CAST, else null. */
    static ColType affinity(Expr e) {
        if (e instanceof Expr.ColumnRef c) return c.type();
        if (e instanceof Expr.Cast c) return c.type();
        if (e instanceof Expr.ScalarSub s) return s.plan().type(0);
        return null;
    }

    /** Converts v (non-NULL) to the affinity's kind as comparison does (SPEC 1.9); null affinity: unchanged. */
    static Object applyAffinity(Object v, ColType aff) {
        if (aff == null) return v;
        return aff.isNumeric() ? textToNumber(v) : numberToText(v);
    }

    /** CAST of a non-NULL value (SPEC 2.3). */
    static Object cast(Object v, ColType type) {
        switch (type) {
            case TEXT:
                return textForm(v);
            case REAL:
                return toDouble(toNumber(v));
            default:
                if (v instanceof Long) return v;
                if (v instanceof Double d) return (long) (double) d;
                return integerPrefix((String) v);
        }
    }

    /** Longest prefix (after whitespace) of optional sign and digits as a Long, else 0. */
    private static long integerPrefix(String s) {
        int n = s.length();
        int i = 0;
        while (i < n && isSpace(s.charAt(i))) i++;
        int start = i;
        if (i < n && (s.charAt(i) == '+' || s.charAt(i) == '-')) i++;
        int digits = i;
        while (i < n && isDigit(s.charAt(i))) i++;
        if (i == digits) return 0;
        boolean neg = s.charAt(start) == '-';
        try {
            return Long.parseLong((neg ? "-" : "") + s.substring(digits, i));
        } catch (NumberFormatException e) {
            return neg ? Long.MIN_VALUE : Long.MAX_VALUE;
        }
    }

    /**
     * Compares a and b as the comparison operators do: applies affinity conversions (SPEC 1.9) first.
     * Both must be non-NULL.
     */
    static int compareWithAffinity(Object a, ColType affA, Object b, ColType affB) {
        if (affA != null && affA.isNumeric() && (affB == null || affB == ColType.TEXT)) {
            b = textToNumber(b);
        } else if (affB != null && affB.isNumeric() && (affA == null || affA == ColType.TEXT)) {
            a = textToNumber(a);
        } else if (affA == ColType.TEXT && affB == null) {
            b = numberToText(b);
        } else if (affB == ColType.TEXT && affA == null) {
            a = numberToText(a);
        }
        return compare(a, b);
    }

    private static Object textToNumber(Object v) {
        if (v instanceof String s) {
            Object n = parseNumericText(s);
            if (n != null) return n;
        }
        return v;
    }

    private static Object numberToText(Object v) {
        return v instanceof String ? v : textForm(v);
    }
}
