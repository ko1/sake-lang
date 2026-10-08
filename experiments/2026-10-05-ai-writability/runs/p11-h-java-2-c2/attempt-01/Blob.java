import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/** A BLOB value (SPEC 7): an immutable string of bytes. Equal exactly when the bytes are equal. */
final class Blob {
    private static final char[] HEX = "0123456789ABCDEF".toCharArray();

    private final byte[] bytes;

    Blob(byte[] bytes) {
        this.bytes = bytes;
    }

    /** The blob of the bytes of a text (UTF-8). */
    static Blob ofText(String s) {
        return new Blob(s.getBytes(StandardCharsets.UTF_8));
    }

    /** The blob for the hex digits of a literal (any case); null if the count is odd or a character is not a digit. */
    static Blob parseHex(String digits) {
        int n = digits.length();
        if (n % 2 != 0) return null;
        byte[] out = new byte[n / 2];
        for (int i = 0; i < out.length; i++) {
            int hi = Character.digit(digits.charAt(2 * i), 16);
            int lo = Character.digit(digits.charAt(2 * i + 1), 16);
            if (hi < 0 || lo < 0 || digits.charAt(2 * i) > 'f' || digits.charAt(2 * i + 1) > 'f') return null;
            out[i] = (byte) (hi * 16 + lo);
        }
        return new Blob(out);
    }

    int length() {
        return bytes.length;
    }

    /** The bytes selected by [from, to) as a new blob. */
    Blob slice(int from, int to) {
        return new Blob(Arrays.copyOfRange(bytes, from, to));
    }

    /** Uppercase hex digits, two per byte. */
    String hex() {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) sb.append(HEX[(b >> 4) & 15]).append(HEX[b & 15]);
        return sb.toString();
    }

    /** The text form (SPEC 7.1): each byte read as one character. */
    String text() {
        return new String(bytes, StandardCharsets.ISO_8859_1);
    }

    /** 1-based position of the first occurrence of other's bytes in these, or 0. */
    long indexOf(Blob other) {
        int n = bytes.length;
        int m = other.bytes.length;
        for (int i = 0; i + m <= n; i++) {
            if (Arrays.equals(bytes, i, i + m, other.bytes, 0, m)) return i + 1;
        }
        return 0;
    }

    /** Byte-wise order on unsigned bytes; a prefix comes first. */
    int compareTo(Blob other) {
        return Integer.signum(Arrays.compareUnsigned(bytes, other.bytes));
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
