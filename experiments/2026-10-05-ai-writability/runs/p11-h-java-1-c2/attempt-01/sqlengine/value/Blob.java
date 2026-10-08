package sqlengine.value;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/** A BLOB value (7.1): immutable bytes; equal exactly when the bytes are equal, so it is usable as a hash key. */
public final class Blob {
    private static final char[] HEX = "0123456789ABCDEF".toCharArray();

    private final byte[] bytes;

    public Blob(byte[] bytes) {
        this.bytes = bytes;
    }

    /** The BLOB of the UTF-8 bytes of s (CAST of TEXT, numbers). */
    public static Blob ofText(String s) {
        return new Blob(s.getBytes(StandardCharsets.UTF_8));
    }

    /** The BLOB of a hexadecimal digit string, or null if it has an odd length or a non-hex character. */
    public static Blob parseHex(String digits) {
        int n = digits.length();
        if (n % 2 != 0) return null;
        byte[] b = new byte[n / 2];
        for (int i = 0; i < b.length; i++) {
            int hi = Character.digit(digits.charAt(2 * i), 16);
            int lo = Character.digit(digits.charAt(2 * i + 1), 16);
            if (hi < 0 || lo < 0 || digits.charAt(2 * i) > 'f' || digits.charAt(2 * i + 1) > 'f') return null;
            b[i] = (byte) (hi * 16 + lo);
        }
        return new Blob(b);
    }

    /** Uppercase hexadecimal digits, two per byte (hex() and the printed form without X'...'). */
    public static String hex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte x : bytes) sb.append(HEX[(x >> 4) & 15]).append(HEX[x & 15]);
        return sb.toString();
    }

    public int length() {
        return bytes.length;
    }

    /** A copy of the bytes [from, to). */
    public Blob slice(int from, int to) {
        return new Blob(Arrays.copyOfRange(bytes, from, to));
    }

    /** 0-based index of the first occurrence of other's bytes, or -1. */
    public int indexOf(Blob other) {
        byte[] o = other.bytes;
        outer:
        for (int i = 0; i + o.length <= bytes.length; i++) {
            for (int j = 0; j < o.length; j++) {
                if (bytes[i + j] != o[j]) continue outer;
            }
            return i;
        }
        return -1;
    }

    /** The text form (7.1): each byte read as one character. */
    public String text() {
        return new String(bytes, StandardCharsets.ISO_8859_1);
    }

    public String hex() {
        return hex(bytes);
    }

    /** Unsigned byte-wise order; a proper prefix comes first. */
    public int compareTo(Blob other) {
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

    @Override
    public String toString() {
        return "X'" + hex() + "'";
    }
}
