package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import sqlengine.value.Collation;
import sqlengine.value.Values;

/** Row equality as SELECT DISTINCT sees it (3.4); shared by DISTINCT, GROUP BY and the compound operators. */
final class RowSets {
    private RowSets() { }

    /** A hashable key: two rows have equal keys exactly when DISTINCT treats them as the same row; collations[i] (null: BINARY) is how column i compares. */
    static List<Object> key(Object[] vals, Collation[] collations) {
        List<Object> key = new ArrayList<>(vals.length);
        for (int i = 0; i < vals.length; i++) key.add(Values.groupKey(vals[i], collations[i]));
        return key;
    }
}
