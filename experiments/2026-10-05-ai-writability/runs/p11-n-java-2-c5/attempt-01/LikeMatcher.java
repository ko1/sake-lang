import java.util.ArrayList;
import java.util.List;

/**
 * SQL LIKE matching: '%' is any run of characters, '_' one character, others match ignoring ASCII case.
 * With an escape character, the character after it is ordinary (SPEC 7.3).
 */
final class LikeMatcher {
    private LikeMatcher() {}

    static boolean matches(String text, String pattern) {
        return matches(text, pattern, null);
    }

    /** escape is null (no ESCAPE clause) or a one-character string. */
    static boolean matches(String text, String pattern, String escape) {
        List<PatternMatch.Item> items = compile(pattern.codePoints().toArray(), escape == null ? -1 : escape.codePointAt(0));
        return items != null && PatternMatch.matches(text.codePoints().toArray(), items);
    }

    /** The items of the pattern, or null when it can match nothing (an escape at the very end). */
    private static List<PatternMatch.Item> compile(int[] pattern, int escape) {
        List<PatternMatch.Item> items = new ArrayList<>();
        for (int i = 0; i < pattern.length; i++) {
            int c = pattern[i];
            if (c == escape) {
                if (++i >= pattern.length) return null;
                items.add(PatternMatch.Item.ch(pattern[i], true));
            } else if (c == '%') {
                items.add(PatternMatch.Item.RUN);
            } else if (c == '_') {
                items.add(PatternMatch.Item.ONE);
            } else {
                items.add(PatternMatch.Item.ch(c, true));
            }
        }
        return items;
    }
}
