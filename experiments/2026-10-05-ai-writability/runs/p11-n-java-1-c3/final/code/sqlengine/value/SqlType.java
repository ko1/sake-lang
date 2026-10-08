package sqlengine.value;

/** Column types (and the names of value types in error messages). */
public enum SqlType {
    INTEGER, REAL, TEXT;

    public boolean isNumeric() {
        return this != TEXT;
    }
}
