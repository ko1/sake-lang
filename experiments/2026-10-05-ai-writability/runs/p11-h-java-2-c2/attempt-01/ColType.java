/** The declared type of a column; also its affinity when compared. */
enum ColType {
    INTEGER, REAL, TEXT, BLOB;

    static ColType parse(String word) {
        return switch (word.toUpperCase(java.util.Locale.ROOT)) {
            case "INTEGER" -> INTEGER;
            case "REAL" -> REAL;
            case "TEXT" -> TEXT;
            case "BLOB" -> BLOB;
            default -> null;
        };
    }

    boolean isNumeric() {
        return this == INTEGER || this == REAL;
    }
}
