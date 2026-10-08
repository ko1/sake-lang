package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import sqlengine.value.Collation;
import sqlengine.value.Values;

/** Row equality as SELECT DISTINCT sees it (3.4); shared by DISTINCT, GROUP BY and the compound operators. */
final class RowSets {
    private RowSets() { }

    /**
     * A hashable key: two rows have equal keys exactly when DISTINCT treats them as the same row, TEXT
     * in column i being compared under colls[i] (7.4).
     */
    static List<Object> key(Object[] vals, Collation[] colls) {
        List<Object> key = new ArrayList<>(vals.length);
        for (int i = 0; i < vals.length; i++) key.add(Values.groupKey(colls[i].foldValue(vals[i])));
        return key;
    }

    /** The BINARY collation for each of n values. */
    static Collation[] binary(int n) {
        Collation[] colls = new Collation[n];
        java.util.Arrays.fill(colls, Collation.BINARY);
        return colls;
    }

    /** The collation of each node, BINARY where it has none (7.4). */
    static Collation[] collationsOf(List<Node> nodes) {
        Collation[] colls = new Collation[nodes.size()];
        for (int i = 0; i < colls.length; i++) colls[i] = Node.collationOrBinary(nodes.get(i));
        return colls;
    }
}
