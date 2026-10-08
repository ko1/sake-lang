package sqlengine.value;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/** A BLOB value: immutable bytes; equal exactly when the bytes are equal (7.3). */
public final class Blob implements Comparable<Blob> {
    private final byte[] bytes;

    public Blob(byte[] bytes) {
        this.bytes = bytes;
    }

    /** The bytes of a TEXT or of a number's text form (CAST ... AS BLOB). */
    public static Blob ofText(String s) {
        return new Blob(s.getBytes(StandardCharsets.UTF_8));
    }

    /** Parses an even-length run of hex digits, or returns null if it is not one. */
    public static Blob ofHex(String hex) {
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

    public int length() {
        return bytes.length;
    }

    public byte[] bytes() {
        return bytes;
    }

    public Blob slice(int from, int to) {
        return new Blob(Arrays.copyOfRange(bytes, from, to));
    }

    /** Index of the first occurrence of other's bytes, or -1. */
    public int indexOf(Blob other) {
        outer:
        for (int i = 0; i + other.bytes.length <= bytes.length; i++) {
            for (int j = 0; j < other.bytes.length; j++) {
                if (bytes[i + j] != other.bytes[j]) continue outer;
            }
            return i;
        }
        return -1;
    }

    /** Uppercase hex, two digits per byte. */
    public String hex() {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) sb.append(Character.toUpperCase(Character.forDigit((b >> 4) & 15, 16)))
            .append(Character.toUpperCase(Character.forDigit(b & 15, 16)));
        return sb.toString();
    }

    /** The bytes read as characters (7.1 "text form"). */
    public String textForm() {
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
