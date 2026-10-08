package sqlengine.exec;

import java.util.Arrays;
import sqlengine.value.Collation;

/**
 * A UNIQUE or (non-rowid) PRIMARY KEY constraint over the columns at these indexes, in declared order;
 * collations[j] is what values of columns[j] are compared under (7.4).
 */
record UniqueKey(int[] columns, Collation[] collations) {

    /** A key over columns that hold no TEXT or compare as BINARY. */
    UniqueKey(int[] columns) {
        this(columns, binary(columns.length));
    }

    private static Collation[] binary(int n) {
        Collation[] colls = new Collation[n];
        Arrays.fill(colls, Collation.BINARY);
        return colls;
    }
}
