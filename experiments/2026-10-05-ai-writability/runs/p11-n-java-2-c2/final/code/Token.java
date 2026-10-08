/**
 * One lexical token. For KEYWORD, text is upper case; for IDENT, the name without quotes;
 * for OP, the operator; for NUMBER, value is a Long or Double; for BLOB, value is a Blob; for STRING, text is the contents.
 */
record Token(Kind kind, String text, Object value) {
    enum Kind { KEYWORD, IDENT, NUMBER, STRING, BLOB, OP, EOF }

    boolean isKeyword(String kw) {
        return kind == Kind.KEYWORD && text.equals(kw);
    }

    boolean isOp(String op) {
        return kind == Kind.OP && text.equals(op);
    }
}
