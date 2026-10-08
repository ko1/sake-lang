package sqlengine.exec;

import sqlengine.value.Collation;
import sqlengine.value.SqlType;

/** A bound (name-resolved) expression, evaluated against one row of the table. */
public interface Node {
    Object eval(Object[] row);

    /** Affinity for comparisons (1.9): the column type for a column reference, else none. */
    default SqlType affinity() {
        return null;
    }

    /** The collation of the expression (7.3), or null when it has none. */
    default Collation collation() {
        return null;
    }

    /** True when collation() was given by COLLATE (explicit) rather than by a column (implicit). */
    default boolean explicitCollation() {
        return false;
    }
}
