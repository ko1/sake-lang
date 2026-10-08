/** SQL LIKE matching: '%' is any run of characters, '_' one character, others match ignoring ASCII case. */
final class LikeMatcher {
    private LikeMatcher() {}

    static boolean matches(String text, String pattern) {
        int t = 0;
        int p = 0;
        int starP = -1;
        int starT = 0;
        while (t < text.length()) {
            if (p < pattern.length() && pattern.charAt(p) == '%') {
                starP = p++;
                starT = t;
            } else if (p < pattern.length() && (pattern.charAt(p) == '_' || same(pattern.charAt(p), text.charAt(t)))) {
                p++;
                t++;
            } else if (starP >= 0) {
                p = starP + 1;
                t = ++starT;
            } else {
                return false;
            }
        }
        while (p < pattern.length() && pattern.charAt(p) == '%') p++;
        return p == pattern.length();
    }

    private static boolean same(char a, char b) {
        return a == b || fold(a) == fold(b);
    }

    private static char fold(char c) {
        return c >= 'A' && c <= 'Z' ? (char) (c + 32) : c;
    }
}
