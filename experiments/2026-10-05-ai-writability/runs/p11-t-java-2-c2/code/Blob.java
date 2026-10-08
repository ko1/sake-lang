import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/** A BLOB value (SPEC 7): an immutable byte string. Its text form reads each byte as one character. */
final class Blob implements Comparable<Blob> {
    private static final char[] HEX = "0123456789ABCDEF".toCharArray();

    private final byte[] bytes;

    Blob(byte[] bytes) {
        this.bytes = bytes;
    }

    /** The blob whose bytes are the chars of s (each below 256), i.e. the inverse of text(). */
    static Blob ofText(String s) {
        return new Blob(s.getBytes(StandardCharsets.ISO_8859_1));
    }

    /** The blob of the UTF-8 bytes of s, as for CAST(text AS BLOB) and hex(). */
    static Blob ofUtf8(String s) {
        return new Blob(s.getBytes(StandardCharsets.UTF_8));
    }

    /** Parses the digits between the quotes of X'..'; an odd count or a non-hex digit is a syntax error. */
    static Blob parseHex(String digits) {
        int n = digits.length();
        if (n % 2 != 0) throw SqlError.syntax();
        byte[] b = new byte[n / 2];
        for (int i = 0; i < b.length; i++) {
            int hi = Character.digit(digits.charAt(2 * i), 16);
            int lo = Character.digit(digits.charAt(2 * i + 1), 16);
            if (hi < 0 || lo < 0 || digits.charAt(2 * i) > 'f' || digits.charAt(2 * i + 1) > 'f') throw SqlError.syntax();
            b[i] = (byte) (hi * 16 + lo);
        }
        return new Blob(b);
    }

    /** Uppercase hex, two digits per byte. */
    String hex() {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte x : bytes) sb.append(HEX[(x >> 4) & 15]).append(HEX[x & 15]);
        return sb.toString();
    }

    /** The text form: one char per byte. */
    String text() {
        return new String(bytes, StandardCharsets.ISO_8859_1);
    }

    @Override
    public int compareTo(Blob o) {
        return Integer.signum(Arrays.compareUnsigned(bytes, o.bytes));
    }

    @Override
    public boolean equals(Object o) {
        return o instanceof Blob b && Arrays.equals(bytes, b.bytes);
    }

    @Override
    public int hashCode() {
        return Arrays.hashCode(bytes);
    }
}
