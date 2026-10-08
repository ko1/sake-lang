package sqlengine.exec;

import sqlengine.parse.SqlError;
import sqlengine.value.Collation;
import sqlengine.value.SqlType;
import sqlengine.value.Values;

/**
 * A table column. The type is enforced when a value is stored (1.5); collation (never null) is how its TEXT values compare.
 * defaultValue (null, Long, Double or String) is used when an INSERT gives the column no value.
 */
public record Column(String name, SqlType type, boolean notNull, Object defaultValue,
                     Collation collation) {

    public Column withNotNull() {
        return new Column(name, type, true, defaultValue, collation);
    }

    /** The collation called name (7.1), or the "no such collation sequence" error. */
    public static Collation collationNamed(String name) {
        Collation c = Collation.named(name);
        if (c == null) throw new SqlError("no such collation sequence: " + name);
        return c;
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
