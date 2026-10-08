package sqlengine.parse;

/** A user-visible SQL error; the message is printed after "Error: ". */
public final class SqlError extends RuntimeException {
    public SqlError(String message) {
        super(message, null, false, false);
    }

    public static SqlError syntax() {
        return new SqlError("syntax error");
    }
}
