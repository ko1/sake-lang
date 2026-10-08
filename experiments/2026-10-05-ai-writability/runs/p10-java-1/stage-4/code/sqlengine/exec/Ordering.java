package sqlengine.exec;

import java.util.List;
import sqlengine.parse.Ast.OrderTerm;
import sqlengine.value.Values;

/** Comparison of rows by ORDER BY terms (1.7); used by SELECT and by ORDER BY inside aggregates. */
final class Ordering {
    private Ordering() { }

    record Key(boolean desc, boolean nullsFirst) {
        /** NULLs come first under ASC and last under DESC unless NULLS FIRST/LAST says otherwise. */
        static Key of(OrderTerm term) {
            return new Key(term.desc(), term.nullsFirst() != null ? term.nullsFirst() : !term.desc());
        }
    }

    /** Compares two arrays of already evaluated term values. */
    static int compare(List<Key> keys, Object[] a, Object[] b) {
        for (int i = 0; i < keys.size(); i++) {
            Key k = keys.get(i);
            Object x = a[i];
            Object y = b[i];
            int c;
            if (x == null || y == null) {
                if (x == y) continue;
                return (x == null) == k.nullsFirst() ? -1 : 1; // explicit placement, not reversed by DESC
            }
            c = Values.compare(x, y);
            if (k.desc()) c = -c;
            if (c != 0) return c;
        }
        return 0;
    }
}
