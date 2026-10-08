package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import sqlengine.value.Values;

/** Row equality as SELECT DISTINCT sees it (3.4); shared by DISTINCT, GROUP BY and the compound operators. */
final class RowSets {
    private RowSets() { }

    /** A hashable key: two rows have equal keys exactly when DISTINCT treats them as the same row. */
    static List<Object> key(Object[] vals) {
        List<Object> key = new ArrayList<>(vals.length);
        for (Object v : vals) key.add(Values.groupKey(v));
        return key;
    }
}
