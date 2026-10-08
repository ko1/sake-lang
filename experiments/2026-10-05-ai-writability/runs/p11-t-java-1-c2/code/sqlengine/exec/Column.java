package sqlengine.exec;

import sqlengine.parse.SqlError;
import sqlengine.value.Blob;
import sqlengine.value.SqlType;
import sqlengine.value.Values;

/**
 * A table column. The type is enforced when a value is stored (1.5).
 * defaultValue (null, Long, Double String or Blob) is used when an INSERT gives the column no value.
 */
public record Column(String name, SqlType type, boolean notNull, Object defaultValue) {

    public Column withNotNull() {
        return new Column(name, type, true, defaultValue);
    }

    /** Converts v to this column's type or throws the "cannot store" error. */
    public Object store(Object v, String table) {
        if (v == null) return null;
        if (v instanceof String s && type.isNumeric()) { // BLOB and TEXT columns never parse text
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
            case BLOB:
                if (v instanceof Blob) return v;
                throw reject(v, table);
            default:
                if (v instanceof Blob) throw reject(v, table);
                return v instanceof String ? v : Values.text(v);
        }
    }

    private SqlError reject(Object v, String table) {
        return new SqlError("cannot store " + (v instanceof Long ? "INT" : Values.typeName(v)) + " value in " + type + " column "
            + table + "." + name);
    }
}
