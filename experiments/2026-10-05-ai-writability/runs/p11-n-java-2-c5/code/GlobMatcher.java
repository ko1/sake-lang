import java.util.ArrayList;
import java.util.List;

/** SQL GLOB matching (SPEC 7.2): case-sensitive; '*' any run, '?' one character, [...] and [^...] classes. */
final class GlobMatcher {
    private GlobMatcher() {}

    static boolean matches(String text, String pattern) {
        List<PatternMatch.Item> items = compile(pattern.codePoints().toArray());
        return items != null && PatternMatch.matches(text.codePoints().toArray(), items);
    }

    /** The items of the pattern, or null when it can match nothing (an unclosed '['). */
    private static List<PatternMatch.Item> compile(int[] pat) {
        List<PatternMatch.Item> items = new ArrayList<>();
        int i = 0;
        while (i < pat.length) {
            int c = pat[i++];
            if (c == '*') {
                items.add(PatternMatch.Item.RUN);
            } else if (c == '?') {
                items.add(PatternMatch.Item.ONE);
            } else if (c == '[') {
                i = appendClass(pat, i, items);
                if (i < 0) return null;
            } else {
                items.add(PatternMatch.Item.ch(c, false));
            }
        }
        return items;
    }

    /** Parses a class whose '[' is just before index i; returns the index after its ']', or -1 if unclosed. */
    private static int appendClass(int[] pat, int i, List<PatternMatch.Item> items) {
        boolean negated = i < pat.length && pat[i] == '^';
        if (negated) i++;
        List<Integer> ranges = new ArrayList<>();
        boolean first = true;
        while (i < pat.length) {
            int c = pat[i];
            if (c == ']' && !first) {
                int[] r = new int[ranges.size()];
                for (int k = 0; k < r.length; k++) r[k] = ranges.get(k);
                items.add(new PatternMatch.Item(PatternMatch.Kind.SET, 0, false, negated, r));
                return i + 1;
            }
            first = false;
            if (i + 2 < pat.length && pat[i + 1] == '-' && pat[i + 2] != ']') {
                ranges.add(c);
                ranges.add(pat[i + 2]);
                i += 3;
            } else {
                ranges.add(c);
                ranges.add(c);
                i++;
            }
        }
        return -1;
    }
}
