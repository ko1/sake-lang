import java.util.List;

/** One element of a compiled LIKE/GLOB pattern, and the matcher that runs a list of them over a text. */
final class PatternMatch {
    private PatternMatch() {}

    enum Kind { RUN, ONE, CHAR, SET }

    /** CHAR uses cp; SET uses ranges (pairs lo, hi, inclusive) and negated. ignoreCase applies to CHAR only. */
    record Item(Kind kind, int cp, boolean ignoreCase, boolean negated, int[] ranges) {
        static final Item RUN = new Item(Kind.RUN, 0, false, false, null);
        static final Item ONE = new Item(Kind.ONE, 0, false, false, null);

        static Item ch(int cp, boolean ignoreCase) {
            return new Item(Kind.CHAR, cp, ignoreCase, false, null);
        }

        /** Matches exactly one character. */
        boolean accepts(int c) {
            switch (kind) {
                case ONE:
                    return true;
                case CHAR:
                    return cp == c || (ignoreCase && fold(cp) == fold(c));
                case SET:
                    for (int i = 0; i < ranges.length; i += 2) {
                        if (c >= ranges[i] && c <= ranges[i + 1]) return !negated;
                    }
                    return negated;
                default:
                    throw new IllegalStateException();
            }
        }
    }

    /** True if the items match the whole of text (RUN items match any sequence, others one character). */
    static boolean matches(int[] text, List<Item> items) {
        int t = 0;
        int p = 0;
        int starP = -1;
        int starT = 0;
        while (t < text.length) {
            if (p < items.size() && items.get(p).kind() == Kind.RUN) {
                starP = p++;
                starT = t;
            } else if (p < items.size() && items.get(p).accepts(text[t])) {
                p++;
                t++;
            } else if (starP >= 0) {
                p = starP + 1;
                t = ++starT;
            } else {
                return false;
            }
        }
        while (p < items.size() && items.get(p).kind() == Kind.RUN) p++;
        return p == items.size();
    }

    private static int fold(int c) {
        return c >= 'A' && c <= 'Z' ? c + 32 : c;
    }
}
