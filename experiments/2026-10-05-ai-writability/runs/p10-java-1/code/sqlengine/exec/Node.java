package sqlengine.exec;

import sqlengine.value.SqlType;

/** A bound (name-resolved) expression, evaluated against one row of the table. */
public interface Node {
    Object eval(Object[] row);

    /** Affinity for comparisons (1.9): the column type for a column reference, else none. */
    default SqlType affinity() {
        return null;
    }
}
