import java.util.List;

/** Comparison of sort-key tuples under ORDER BY terms (used by SELECT and by group_concat(... ORDER BY)). */
final class Sorting {
    private Sorting() {}

    /** Direction of one ORDER BY term; nullsFirst is null when the statement does not say; collation orders TEXT. */
    record Term(boolean desc, Boolean nullsFirst, Collation collation) {}

    /** Orders key tuples a and b term by term; NULLs come first under ASC and last under DESC by default. */
    static int compare(List<Term> terms, Object[] a, Object[] b) {
        for (int i = 0; i < terms.size(); i++) {
            Term t = terms.get(i);
            Object x = a[i];
            Object y = b[i];
            if (x == null || y == null) {
                if (x == y) continue;
                boolean nullsFirst = t.nullsFirst() != null ? t.nullsFirst() : !t.desc();
                return (x == null) == nullsFirst ? -1 : 1;
            }
            int c = Values.compare(x, y, t.collation());
            if (c != 0) return t.desc() ? -c : c;
        }
        return 0;
    }
}
