import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/** A BLOB value (SPEC 7): an immutable string of bytes. Equal exactly when the bytes are equal. */
final class Blob {
    private static final char[] HEX = "0123456789ABCDEF".toCharArray();

    private final byte[] bytes;

    Blob(byte[] bytes) {
        this.bytes = bytes;
    }

    /** The BLOB of the UTF-8 bytes of a text (CAST ... AS BLOB). */
    static Blob ofText(String s) {
        return new Blob(s.getBytes(StandardCharsets.UTF_8));
    }

    /** The BLOB for hexadecimal digits (either case), or a syntax error for an odd count or a non-digit. */
    static Blob parseHex(String digits) {
        int n = digits.length();
        if (n % 2 != 0) throw SqlError.syntax();
        byte[] out = new byte[n / 2];
        for (int i = 0; i < out.length; i++) {
            int hi = Character.digit(digits.charAt(2 * i), 16);
            int lo = Character.digit(digits.charAt(2 * i + 1), 16);
            if (hi < 0 || lo < 0 || digits.charAt(2 * i) > 'f' || digits.charAt(2 * i + 1) > 'f') {
                throw SqlError.syntax();
            }
            out[i] = (byte) (hi * 16 + lo);
        }
        return new Blob(out);
    }

    int length() {
        return bytes.length;
    }

    /** The bytes [from, to) as a BLOB. */
    Blob slice(int from, int to) {
        return new Blob(Arrays.copyOfRange(bytes, from, to));
    }

    /** The text form (SPEC 7.1): each byte read as one character. */
    String text() {
        return new String(bytes, StandardCharsets.ISO_8859_1);
    }

    /** Two uppercase hexadecimal digits per byte. */
    static String hex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) sb.append(HEX[(b >> 4) & 15]).append(HEX[b & 15]);
        return sb.toString();
    }

    String hex() {
        return hex(bytes);
    }

    /** The printed form X'..' (SPEC 7.1). */
    String literal() {
        return "X'" + hex() + "'";
    }

    /** Bytewise order as unsigned bytes; a proper prefix comes first. */
    int compareTo(Blob o) {
        return Integer.signum(Arrays.compareUnsigned(bytes, o.bytes));
    }

    @Override public boolean equals(Object o) {
        return o instanceof Blob b && Arrays.equals(bytes, b.bytes);
    }

    @Override public int hashCode() {
        return Arrays.hashCode(bytes);
    }
}
