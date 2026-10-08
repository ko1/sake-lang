package sqlengine.parse;

/**
 * One lexical token. text: keyword in upper case, identifier as written (quotes removed),
 * operator spelling, or string contents. value: Long/Double for NUMBER, Blob for BLOB, else null.
 */
public record Token(Kind kind, String text, Object value) {
    public enum Kind { KEYWORD, IDENT, NUMBER, STRING, BLOB, OP, ERROR, EOF }

    public boolean isKeyword(String kw) {
        return kind == Kind.KEYWORD && text.equals(kw);
    }

    public boolean isOp(String op) {
        return kind == Kind.OP && text.equals(op);
    }
}
