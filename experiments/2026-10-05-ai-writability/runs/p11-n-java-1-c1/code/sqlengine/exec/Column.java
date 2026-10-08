package sqlengine.exec;

import sqlengine.parse.SqlError;
import sqlengine.value.Collation;
import sqlengine.value.SqlType;
import sqlengine.value.Values;

/**
 * A table column. The type is enforced when a value is stored (1.5).
 * defaultValue (null, Long, Double or String) is used when an INSERT gives the column no value.
 * collation is the column's collating sequence (7.3); for a result column of a query it is null when the
 * expression has none, and collationExplicit tells whether it was written as COLLATE there.
 */
public record Column(String name, SqlType type, boolean notNull, Object defaultValue, Collation collation,
                     boolean collationExplicit) {

    /** A column with no collation of its own (BINARY when referenced). */
    public Column(String name, SqlType type, boolean notNull, Object defaultValue) {
        this(name, type, notNull, defaultValue, null, false);
    }

    public Column withNotNull() {
        return new Column(name, type, true, defaultValue, collation, collationExplicit);
    }

    public Column renamed(String newName) {
        return new Column(newName, type, notNull, defaultValue, collation, collationExplicit);
    }

    /** The implicit collation of a reference to this column (7.3): BINARY when it has none. */
    public Collation implicitCollation() {
        return collation == null ? Collation.BINARY : collation;
    }

    /** Converts v to this column's type or throws the "cannot store" error. */
    public Object store(Object v, String table) {
        if (v == null) return null;
        if (v instanceof String s && type.isNumeric()) {
            Number n = Values.parseNumericLiteral(s);
            if (n != null) v = n;
        }
        switch (type) {
            case INTEGER:
                if (v instanceof Long) return v;
                if (v instanceof Double d && d == Math.rint(d) && d >= -0x1p63 && d < 0x1p63) {
                    return (long) (double) d;
                }
                throw reject(v, table);
            case REAL:
                if (v instanceof Long l) return (double) l;
                if (v instanceof Double) return v;
                throw reject(v, table);
            default:
                return v instanceof String ? v : Values.text(v);
        }
    }

    private SqlError reject(Object v, String table) {
        return new SqlError("cannot store " + Values.typeName(v) + " value in " + type + " column "
            + table + "." + name);
    }
}
