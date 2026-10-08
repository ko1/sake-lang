import java.util.ArrayList;
import java.util.List;

/** Splits a script into statement texts at ';' that is outside literals, quoted names and comments. */
final class Script {
    private Script() {}

    static List<String> split(String src) {
        List<String> out = new ArrayList<>();
        int n = src.length();
        int start = 0;
        int i = 0;
        while (i < n) {
            char c = src.charAt(i);
            if (c == '\'' || c == '"') {
                i = skipQuoted(src, i, c);
            } else if (c == '-' && i + 1 < n && src.charAt(i + 1) == '-') {
                while (i < n && src.charAt(i) != '\n') i++;
            } else if (c == '/' && i + 1 < n && src.charAt(i + 1) == '*') {
                int end = src.indexOf("*/", i + 2);
                i = end < 0 ? n : end + 2;
            } else if (c == ';') {
                out.add(src.substring(start, i));
                start = ++i;
            } else {
                i++;
            }
        }
        if (start < n) out.add(src.substring(start));
        return out;
    }

    /** Index just after the quoted text starting at i; a doubled quote stays inside. */
    private static int skipQuoted(String src, int i, char q) {
        int n = src.length();
        i++;
        while (i < n) {
            if (src.charAt(i) == q) {
                if (i + 1 < n && src.charAt(i + 1) == q) i += 2;
                else return i + 1;
            } else {
                i++;
            }
        }
        return n;
    }
}
