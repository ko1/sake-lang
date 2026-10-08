import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * The sources of one FROM and the layout of a joined row: the columns of each source, one after the other.
 * A column index in a joined row is the "flat index" used by Expr.ColumnRef.
 */
final class Scope {
    /**
     * One source; name is its alias or table name (null for an unnamed subquery); types hold null for no affinity.
     * A table source (hasRowid) has one more slot after its real columns, holding the row's rowid (SPEC 7.1).
     */
    record Source(String name, List<String> columns, List<ColType> types, int offset, boolean hasRowid) {
        /** Number of slots this source takes in a joined row: the real columns plus the rowid, if any. */
        int width() {
            return columns.size() + (hasRowid ? 1 : 0);
        }

        /** Flat index of the rowid slot (meaningful only if hasRowid). */
        int rowidIndex() {
            return offset + columns.size();
        }

        int columnIndex(String column) {
            for (int i = 0; i < columns.size(); i++) if (columns.get(i).equalsIgnoreCase(column)) return i;
            return -1;
        }
    }

    static final int NOT_FOUND = -1;
    static final int AMBIGUOUS = -2;

    private final List<Source> sources = new ArrayList<>();
    /** Flat indexes of the right-hand copy of a USING column: not found by bare name, not expanded by '*'. */
    private final Set<Integer> merged = new HashSet<>();
    private int width;

    int width() {
        return width;
    }

    List<Source> sources() {
        return sources;
    }

    Source add(String name, List<String> columns, List<ColType> types, boolean hasRowid) {
        Source s = new Source(name, columns, types, width, hasRowid);
        sources.add(s);
        width += s.width();
        return s;
    }

    /** Marks column c of source s as a USING duplicate of an earlier column. */
    void merge(Source s, int c) {
        merged.add(s.offset() + c);
    }

    boolean isMerged(int flatIndex) {
        return merged.contains(flatIndex);
    }

    /** The scope of the first n sources only (what an ON clause can see). */
    Scope prefix(int n) {
        Scope p = new Scope();
        for (int i = 0; i < n; i++) {
            Source s = sources.get(i);
            p.add(s.name(), s.columns(), s.types(), s.hasRowid());
        }
        for (int m : merged) if (m < p.width) p.merged.add(m);
        return p;
    }

    /** The source with this name, or null. */
    Source find(String name) {
        for (Source s : sources) if (s.name() != null && s.name().equalsIgnoreCase(name)) return s;
        return null;
    }

    /** Flat index of the one visible column with this name, NOT_FOUND, or AMBIGUOUS. */
    int lookup(String column) {
        int found = NOT_FOUND;
        for (Source s : sources) {
            int c = s.columnIndex(column);
            if (c < 0 || merged.contains(s.offset() + c)) continue;
            if (found != NOT_FOUND) return AMBIGUOUS;
            found = s.offset() + c;
        }
        return found;
    }

    /** Flat index of the first source's column with this name (merged or not), or NOT_FOUND. */
    int first(String column) {
        for (Source s : sources) {
            int c = s.columnIndex(column);
            if (c >= 0) return s.offset() + c;
        }
        return NOT_FOUND;
    }

    ColType typeAt(int flatIndex) {
        for (Source s : sources) {
            if (flatIndex < s.offset() + s.width()) {
                int i = flatIndex - s.offset();
                return i < s.columns().size() ? s.types().get(i) : ColType.INTEGER;
            }
        }
        throw new IllegalArgumentException("column " + flatIndex);
    }
}
