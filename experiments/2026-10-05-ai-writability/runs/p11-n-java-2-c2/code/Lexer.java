import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Turns the text of one statement into tokens; any malformed input is a syntax error. */
final class Lexer {
    static final Set<String> KEYWORDS = Set.of(
        "ADD", "ALL", "ALTER", "AND", "AS", "ASC", "BEGIN", "BETWEEN", "BY", "CASE", "CAST", "COLUMN", "COMMIT",
        "CREATE", "CROSS", "CURRENT", "DEFAULT", "DELETE", "DESC", "DISTINCT", "DROP", "ELSE", "END", "EXCEPT",
        "EXISTS", "FIRST", "FOLLOWING", "FROM", "GROUP", "HAVING", "IF", "IN", "INDEX", "INNER", "INSERT",
        "INTERSECT", "INTO", "IS", "JOIN", "KEY", "LAST", "LEFT", "LIKE", "LIMIT", "NOT", "NULL", "NULLS", "OFFSET",
        "ON", "OR", "ORDER", "OUTER", "OVER", "PARTITION", "PRECEDING", "PRIMARY", "RANGE", "RECURSIVE", "RENAME",
        "ROLLBACK", "ROW", "ROWS", "SELECT", "SET", "TABLE", "THEN", "TO", "TRANSACTION", "UNBOUNDED", "UNION",
        "UNIQUE", "UPDATE", "USING", "VALUES", "VIEW", "WHEN", "WHERE", "WINDOW", "WITH");

    private final String src;
    private int pos;

    private Lexer(String src) {
        this.src = src;
    }

    /** All tokens of the statement, ending with an EOF token. */
    static List<Token> tokenize(String src) {
        return new Lexer(src).run();
    }

    private List<Token> run() {
        List<Token> out = new ArrayList<>();
        int n = src.length();
        while (true) {
            skipBlanks();
            if (pos >= n) break;
            char c = src.charAt(pos);
            if ((c == 'x' || c == 'X') && pos + 1 < n && src.charAt(pos + 1) == '\'') out.add(blob());
            else if (isLetter(c)) out.add(word());
            else if (isDigit(c) || (c == '.' && pos + 1 < n && isDigit(src.charAt(pos + 1)))) out.add(number());
            else if (c == '\'') out.add(new Token(Token.Kind.STRING, quoted('\''), null));
            else if (c == '"') out.add(new Token(Token.Kind.IDENT, quoted('"'), null));
            else out.add(operator());
        }
        out.add(new Token(Token.Kind.EOF, "", null));
        return out;
    }

    private void skipBlanks() {
        int n = src.length();
        while (pos < n) {
            char c = src.charAt(pos);
            if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
                pos++;
            } else if (c == '-' && pos + 1 < n && src.charAt(pos + 1) == '-') {
                while (pos < n && src.charAt(pos) != '\n') pos++;
            } else if (c == '/' && pos + 1 < n && src.charAt(pos + 1) == '*') {
                int end = src.indexOf("*/", pos + 2);
                pos = end < 0 ? n : end + 2;
            } else {
                return;
            }
        }
    }

    private Token word() {
        int start = pos;
        while (pos < src.length() && (isLetter(src.charAt(pos)) || isDigit(src.charAt(pos)))) pos++;
        String text = src.substring(start, pos);
        String upper = text.toUpperCase(java.util.Locale.ROOT);
        if (KEYWORDS.contains(upper)) return new Token(Token.Kind.KEYWORD, upper, null);
        return new Token(Token.Kind.IDENT, text, null);
    }

    /** X'hex' / x'hex': nothing but hex digits (an even number) may sit between the quotes. */
    private Token blob() {
        int close = src.indexOf('\'', pos + 2);
        if (close < 0) throw SqlError.syntax();
        Blob b = Blob.parseHex(src.substring(pos + 2, close));
        pos = close + 1;
        return new Token(Token.Kind.BLOB, "", b);
    }

    private Token number() {
        int end = Values.scanNumber(src, pos);
        String text = src.substring(pos, end);
        pos = end;
        Object v = Values.parseNumber(text);
        return new Token(Token.Kind.NUMBER, text, v);
    }

    /** Reads a quoted text starting at the opening quote; a doubled quote is one quote. */
    private String quoted(char q) {
        StringBuilder sb = new StringBuilder();
        int n = src.length();
        pos++;
        while (pos < n) {
            char c = src.charAt(pos);
            if (c == q) {
                if (pos + 1 < n && src.charAt(pos + 1) == q) {
                    sb.append(q);
                    pos += 2;
                } else {
                    pos++;
                    return sb.toString();
                }
            } else {
                sb.append(c);
                pos++;
            }
        }
        throw SqlError.syntax();
    }

    private Token operator() {
        char c = src.charAt(pos);
        char d = pos + 1 < src.length() ? src.charAt(pos + 1) : '\0';
        String op;
        if (c == '|' && d == '|') op = "||";
        else if (c == '<' && (d == '=' || d == '>')) op = "" + c + d;
        else if (c == '>' && d == '=') op = ">=";
        else if (c == '=' && d == '=') op = "==";
        else if (c == '!' && d == '=') op = "!=";
        else if ("+-*/%=<>(),.".indexOf(c) >= 0) op = String.valueOf(c);
        else throw SqlError.syntax();
        pos += op.length();
        return new Token(Token.Kind.OP, op, null);
    }

    private static boolean isLetter(char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
    }

    private static boolean isDigit(char c) {
        return c >= '0' && c <= '9';
    }
}
