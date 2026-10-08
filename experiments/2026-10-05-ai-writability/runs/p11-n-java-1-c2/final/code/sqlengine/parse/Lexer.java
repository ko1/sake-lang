package sqlengine.parse;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import sqlengine.value.Blob;

/** Turns a whole script into tokens. Malformed input becomes ERROR tokens (a syntax error later). */
public final class Lexer {
    public static final Set<String> KEYWORDS = Set.of(
        "ADD", "ALL", "ALTER", "AND", "AS", "ASC", "BEGIN", "BETWEEN", "BY", "CASE", "CAST", "COLUMN",
        "COMMIT", "CREATE", "CROSS", "CURRENT", "DEFAULT", "DELETE", "DESC", "DISTINCT", "DROP", "ELSE",
        "END", "EXCEPT", "EXISTS", "FIRST", "FOLLOWING", "FROM", "GROUP", "HAVING", "IF", "IN", "INDEX",
        "INNER", "INSERT", "INTERSECT", "INTO", "IS", "JOIN", "KEY", "LAST", "LEFT", "LIKE", "LIMIT", "NOT",
        "NULL", "NULLS", "OFFSET", "ON", "OR", "ORDER", "OUTER", "OVER", "PARTITION", "PRECEDING", "PRIMARY",
        "RANGE", "RECURSIVE", "RENAME", "ROLLBACK", "ROW", "ROWS", "SELECT", "SET", "TABLE", "THEN", "TO",
        "TRANSACTION", "UNBOUNDED", "UNION", "UNIQUE", "UPDATE", "USING", "VALUES", "VIEW", "WHEN", "WHERE",
        "WINDOW", "WITH");

    private final String src;
    private int pos = 0;
    private final List<Token> out = new ArrayList<>();

    private Lexer(String src) {
        this.src = src;
    }

    public static List<Token> tokenize(String src) {
        Lexer lx = new Lexer(src);
        lx.run();
        return lx.out;
    }

    private void add(Token.Kind k, String text, Object value) {
        out.add(new Token(k, text, value));
    }

    private static boolean isDigit(char c) {
        return c >= '0' && c <= '9';
    }

    private static boolean isIdentStart(char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
    }

    private char at(int i) {
        return i < src.length() ? src.charAt(i) : '\0';
    }

    private void run() {
        int n = src.length();
        while (pos < n) {
            char c = src.charAt(pos);
            if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
                pos++;
            } else if (c == '-' && at(pos + 1) == '-') {
                while (pos < n && src.charAt(pos) != '\n') pos++;
            } else if (c == '/' && at(pos + 1) == '*') {
                int end = src.indexOf("*/", pos + 2);
                pos = end < 0 ? n : end + 2;
            } else if ((c == 'x' || c == 'X') && at(pos + 1) == '\'') {
                blob();
            } else if (isIdentStart(c)) {
                int s = pos;
                while (pos < n && (isIdentStart(src.charAt(pos)) || isDigit(src.charAt(pos)))) pos++;
                String word = src.substring(s, pos);
                String up = word.toUpperCase(java.util.Locale.ROOT);
                if (KEYWORDS.contains(up)) add(Token.Kind.KEYWORD, up, null);
                else add(Token.Kind.IDENT, word, null);
            } else if (isDigit(c) || (c == '.' && isDigit(at(pos + 1)))) {
                number();
            } else if (c == '\'') {
                quoted('\'', Token.Kind.STRING);
            } else if (c == '"') {
                quoted('"', Token.Kind.IDENT);
            } else {
                operator(c);
            }
        }
    }

    private void number() {
        int n = src.length();
        int s = pos;
        boolean real = false;
        while (pos < n && isDigit(src.charAt(pos))) pos++;
        if (at(pos) == '.') {
            real = true;
            pos++;
            while (pos < n && isDigit(src.charAt(pos))) pos++;
        }
        char e = at(pos);
        if (e == 'e' || e == 'E') {
            int p = pos + 1;
            if (at(p) == '+' || at(p) == '-') p++;
            if (isDigit(at(p))) {
                while (p < n && isDigit(src.charAt(p))) p++;
                pos = p;
                real = true;
            }
        }
        String text = src.substring(s, pos);
        Object v;
        if (!real) {
            try {
                v = Long.parseLong(text);
            } catch (NumberFormatException ex) {
                v = Double.parseDouble(text);
            }
        } else {
            v = Double.parseDouble(text);
        }
        add(Token.Kind.NUMBER, text, v);
    }

    /** X'hex': up to the next quote; odd length or a non-hex character makes an ERROR token (syntax error). */
    private void blob() {
        int close = src.indexOf('\'', pos + 2);
        if (close < 0) {
            pos = src.length();
            add(Token.Kind.ERROR, "unterminated", null);
            return;
        }
        Blob b = Blob.fromHex(src.substring(pos + 2, close));
        pos = close + 1;
        if (b == null) add(Token.Kind.ERROR, "blob", null);
        else add(Token.Kind.BLOB, "", b);
    }

    /** Quoted text with doubled quote as escape; an unterminated one is an ERROR token. */
    private void quoted(char q, Token.Kind kind) {
        int n = src.length();
        StringBuilder sb = new StringBuilder();
        pos++;
        while (pos < n) {
            char c = src.charAt(pos);
            if (c == q) {
                if (at(pos + 1) == q) {
                    sb.append(q);
                    pos += 2;
                    continue;
                }
                pos++;
                add(kind, sb.toString(), null);
                return;
            }
            sb.append(c);
            pos++;
        }
        add(Token.Kind.ERROR, "unterminated", null);
    }

    private void operator(char c) {
        String two = pos + 1 < src.length() ? src.substring(pos, pos + 2) : "";
        switch (two) {
            case "||", "<=", ">=", "<>", "!=", "==" -> {
                add(Token.Kind.OP, two, null);
                pos += 2;
                return;
            }
            default -> { }
        }
        if ("+-*/%=<>(),;.".indexOf(c) >= 0) add(Token.Kind.OP, String.valueOf(c), null);
        else add(Token.Kind.ERROR, String.valueOf(c), null);
        pos++;
    }
}
