import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;

/** Prints a double like C's "%.15g", then applies the engine's ".0" rules (SPEC 1.3). */
final class RealFormat {
    private RealFormat() {}

    static String format(double x) {
        if (x == 0) return "0.0";
        BigDecimal r = new BigDecimal(x).round(new MathContext(15, RoundingMode.HALF_EVEN));
        String digits = r.unscaledValue().abs().toString();
        int exp = digits.length() - 1 - r.scale();  // decimal exponent of the first digit
        digits = stripZeros(digits);
        StringBuilder sb = new StringBuilder();
        if (r.signum() < 0) sb.append('-');
        if (exp < -4 || exp >= 15) {
            sb.append(digits.charAt(0));
            if (digits.length() > 1) sb.append('.').append(digits, 1, digits.length());
            else sb.append(".0");
            sb.append('e').append(exp < 0 ? '-' : '+');
            int a = Math.abs(exp);
            if (a < 10) sb.append('0');
            sb.append(a);
        } else if (exp < 0) {
            sb.append("0.");
            for (int i = 0; i < -exp - 1; i++) sb.append('0');
            sb.append(digits);
        } else if (digits.length() <= exp + 1) {
            sb.append(digits);
            for (int i = digits.length(); i < exp + 1; i++) sb.append('0');
            sb.append(".0");
        } else {
            sb.append(digits, 0, exp + 1).append('.').append(digits, exp + 1, digits.length());
        }
        return sb.toString();
    }

    private static String stripZeros(String d) {
        int end = d.length();
        while (end > 1 && d.charAt(end - 1) == '0') end--;
        return d.substring(0, end);
    }
}
