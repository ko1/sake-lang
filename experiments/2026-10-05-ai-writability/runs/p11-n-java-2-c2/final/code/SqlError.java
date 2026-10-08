/** An error reported to the script as one "Error: <message>" line; the failing statement has no effect. */
final class SqlError extends RuntimeException {
    private static final long serialVersionUID = 1L;

    SqlError(String message) {
        super(message, null, false, false);
    }

    static SqlError syntax() {
        return new SqlError("syntax error");
    }
}
