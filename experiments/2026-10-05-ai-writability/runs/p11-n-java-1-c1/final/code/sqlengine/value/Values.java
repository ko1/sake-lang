package sqlengine.value;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Runtime values are plain Java objects: null (NULL), Long (INTEGER), Double (REAL), String (TEXT).
 * This class holds everything about their text forms, numeric reading, ordering and truth.
 */
public final class Values {
    private Values() { }

    private static final String NUM = "[+-]?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?";
    private static final Pattern NUMERIC_LITERAL = Pattern.compile(NUM);

    // ---- type names ----
    public static String typeName(Object v) {
        if (v == null) return "NULL";
        if (v instanceof Long) return "INTEGER";
        if (v instanceof Double) return "REAL";
        return "TEXT";
    }

    // ---- text forms ----
    /** Text form of a non-NULL value; what a result row prints for it as well. */
    public static String text(Object v) {
        if (v instanceof Long l) return Long.toString(l);
        if (v instanceof Double d) return formatReal(d);
        return (String) v;
    }

    public static String display(Object v) {
        return v == null ? "NULL" : text(v);
    }

    /** C's printf("%.15g") followed by the ".0" rules of the specification. */
    public static String formatReal(double d) {
        if (d == 0) return "0.0";
        BigDecimal bd = new BigDecimal(d).round(new MathContext(15, RoundingMode.HALF_EVEN));
        String digits = bd.unscaledValue().abs().toString();
        int exp = digits.length() - 1 - bd.scale();
        int end = digits.length();
        while (end > 1 && digits.charAt(end - 1) == '0') end--;
        digits = digits.substring(0, end);
        StringBuilder sb = new StringBuilder();
        if (d < 0) sb.append('-');
        if (exp < -4 || exp >= 15) {
            sb.append(digits.charAt(0)).append('.');
            sb.append(digits.length() > 1 ? digits.substring(1) : "0");
            sb.append('e').append(exp < 0 ? '-' : '+');
            int a = Math.abs(exp);
            if (a < 10) sb.append('0');
            sb.append(a);
        } else if (exp >= 0) {
            int intLen = exp + 1;
            if (digits.length() <= intLen) {
                sb.append(digits).append("0".repeat(intLen - digits.length())).append(".0");
            } else {
                sb.append(digits, 0, intLen).append('.').append(digits.substring(intLen));
            }
        } else {
            sb.append("0.").append("0".repeat(-exp - 1)).append(digits);
        }
        return sb.toString();
    }

    // ---- reading numbers from text ----
    private static boolean isWs(char c) {
        return c == ' ' || c == '\t' || c == '\n' || c == '\r';
    }

    private static String trim(String s) {
        int a = 0;
        int b = s.length();
        while (a < b && isWs(s.charAt(a))) a++;
        while (b > a && isWs(s.charAt(b - 1))) b--;
        return s.substring(a, b);
    }

    private static Number toNumber(String lit) {
        boolean real = lit.indexOf('.') >= 0 || lit.indexOf('e') >= 0 || lit.indexOf('E') >= 0;
        if (!real) {
            try {
                return Long.parseLong(lit);
            } catch (NumberFormatException e) {
                // beyond 64 bits: falls back to REAL
            }
        }
        return Double.parseDouble(lit);
    }

    /** The whole text (after trimming) as a numeric literal: Long or Double, or null if it is not one. */
    public static Number parseNumericLiteral(String s) {
        String t = trim(s);
        return NUMERIC_LITERAL.matcher(t).matches() ? toNumber(t) : null;
    }

    /** The "numeric prefix" reading of text: always a Long or Double (0 when there is no prefix). */
    public static Number numericPrefix(String s) {
        int a = 0;
        while (a < s.length() && isWs(s.charAt(a))) a++;
        Matcher m = NUMERIC_LITERAL.matcher(s);
        m.region(a, s.length());
        if (m.lookingAt()) return toNumber(m.group());
        return 0L;
    }

    /** CAST(text AS INTEGER): leading whitespace, optional sign, digits; 0 if none; saturates at 64 bits. */
    public static long integerPrefix(String s) {
        int a = 0;
        while (a < s.length() && isWs(s.charAt(a))) a++;
        int b = a;
        if (b < s.length() && (s.charAt(b) == '+' || s.charAt(b) == '-')) b++;
        int digits = b;
        while (b < s.length() && s.charAt(b) >= '0' && s.charAt(b) <= '9') b++;
        if (b == digits) return 0;
        BigInteger n = new BigInteger(s.substring(s.charAt(a) == '+' ? a + 1 : a, b));
        if (n.bitLength() > 63) return n.signum() < 0 ? Long.MIN_VALUE : Long.MAX_VALUE;
        return n.longValue();
    }

    /** A non-NULL value as a number: numbers as they are, text by numeric prefix. */
    public static Number toNumber(Object v) {
        if (v instanceof Number n) return n;
        return numericPrefix((String) v);
    }

    // ---- truth ----
    /** Truth value of 1.10: TRUE, FALSE, or null for unknown. */
    public static Boolean truth(Object v) {
        if (v == null) return null;
        Number n = toNumber(v);
        if (n instanceof Long l) return l != 0;
        return n.doubleValue() != 0;
    }

    public static Object fromBoolean(Boolean b) {
        return b == null ? null : (b ? 1L : 0L);
    }

    // ---- order ----
    private static int rank(Object v) {
        return v == null ? 0 : (v instanceof String ? 2 : 1);
    }

    /** Total order of values (1.9): NULL < numbers < TEXT. */
    public static int compare(Object a, Object b) {
        return compare(a, b, Collation.BINARY);
    }

    /** As compare, where two TEXT values are compared under coll (7.1). */
    public static int compare(Object a, Object b, Collation coll) {
        int ra = rank(a);
        int rb = rank(b);
        if (ra != rb) return ra < rb ? -1 : 1;
        if (ra == 0) return 0;
        if (ra == 2) return coll.compare((String) a, (String) b);
        if (a instanceof Long x && b instanceof Long y) return Long.compare(x, y);
        double x = ((Number) a).doubleValue();
        double y = ((Number) b).doubleValue();
        return x < y ? -1 : (x > y ? 1 : 0);
    }

    /** A hashable stand-in for v such that equal values (1.9, so 1 and 1.0) have equal keys; NULL maps to null. */
    public static Object groupKey(Object v) {
        if (v instanceof Double d && d == Math.rint(d) && Math.abs(d) < 0x1p63) return (long) (double) d;
        return v;
    }

    // ---- affinity (1.9) ----
    /**
     * Compares a and b (both non-NULL) after converting by the operands' affinities (null = none); TEXT is
     * compared under coll.
     */
    public static int compareWithAffinity(Object a, SqlType la, Object b, SqlType lb, Collation coll) {
        if (la != null && la.isNumeric() && (lb == null || lb == SqlType.TEXT)) {
            b = numberFromText(b);
        } else if (lb != null && lb.isNumeric() && (la == null || la == SqlType.TEXT)) {
            a = numberFromText(a);
        } else if (la == SqlType.TEXT && lb == null) {
            b = textFromNumber(b);
        } else if (lb == SqlType.TEXT && la == null) {
            a = textFromNumber(a);
        }
        return compare(a, b, coll);
    }

    private static Object numberFromText(Object v) {
        if (v instanceof String s) {
            Number n = parseNumericLiteral(s);
            return n != null ? n : v;
        }
        return v;
    }

    private static Object textFromNumber(Object v) {
        return v instanceof String ? v : text(v);
    }
}
