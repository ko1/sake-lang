package sqlengine.value;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/** The runtime BLOB value: an immutable byte string; equal exactly when the bytes are equal. */
public final class Blob {
    private final byte[] bytes;

    /** Takes ownership of bytes; callers must not modify the array afterwards. */
    public Blob(byte[] bytes) {
        this.bytes = bytes;
    }

    /** The blob of a hex digit string (even length, hex digits only), or null if it is malformed. */
    public static Blob fromHex(String hex) {
        if (hex.length() % 2 != 0) return null;
        byte[] b = new byte[hex.length() / 2];
        for (int i = 0; i < b.length; i++) {
            int hi = Character.digit(hex.charAt(2 * i), 16);
            int lo = Character.digit(hex.charAt(2 * i + 1), 16);
            if (hi < 0 || lo < 0 || hex.charAt(2 * i) > 'f' || hex.charAt(2 * i + 1) > 'f') return null;
            b[i] = (byte) (hi * 16 + lo);
        }
        return new Blob(b);
    }

    /** The bytes of a text (UTF-8). */
    public static Blob ofText(String s) {
        return new Blob(s.getBytes(StandardCharsets.UTF_8));
    }

    public int length() {
        return bytes.length;
    }

    public byte[] bytes() {
        return bytes;
    }

    /** Two uppercase hex digits per byte. */
    public String hex() {
        return hex(bytes);
    }

    public static String hex(byte[] b) {
        char[] digits = "0123456789ABCDEF".toCharArray();
        StringBuilder sb = new StringBuilder(b.length * 2);
        for (byte x : b) sb.append(digits[(x >> 4) & 15]).append(digits[x & 15]);
        return sb.toString();
    }

    /** The bytes read as characters (the "text form" of 7.1; exact for ASCII). */
    public String textForm() {
        return new String(bytes, StandardCharsets.ISO_8859_1);
    }

    /** Byte-wise unsigned order; a proper prefix comes first. */
    public int compareTo(Blob o) {
        return Integer.signum(Arrays.compareUnsigned(bytes, o.bytes));
    }

    /** 1-based position of the first occurrence of needle, or 0. */
    public int indexOf(Blob needle) {
        byte[] n = needle.bytes;
        for (int i = 0; i + n.length <= bytes.length; i++) {
            if (Arrays.equals(bytes, i, i + n.length, n, 0, n.length)) return i + 1;
        }
        return 0;
    }

    public Blob slice(int from, int to) {
        return new Blob(Arrays.copyOfRange(bytes, from, to));
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
