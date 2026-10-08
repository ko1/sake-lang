package sqlengine.exec;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;

/**
 * The shape of a joined row: the sources' columns laid out one after another, plus the USING merges
 * (4.1, 4.2). Immutable; plus() and merging() return the extended layout.
 */
final class Layout {
    static final Layout EMPTY = new Layout(List.of(), Set.of(), Set.of(), 0);

    private final List<Source> sources;
    private final Set<String> merged;   // normalised names of USING columns: one column, the left one wins
    private final Set<Integer> hidden;  // flat indexes of right-side USING copies, left out of "*"
    private final int width;

    private Layout(List<Source> sources, Set<String> merged, Set<Integer> hidden, int width) {
        this.sources = sources;
        this.merged = merged;
        this.hidden = hidden;
        this.width = width;
    }

    int width() {
        return width;
    }

    List<Source> sources() {
        return sources;
    }

    boolean isHidden(int flat) {
        return hidden.contains(flat);
    }

    Layout plus(String name, List<Column> columns) {
        List<Source> s = new ArrayList<>(sources);
        s.add(new Source(name, columns, width));
        return new Layout(s, merged, hidden, width + columns.size());
    }

    /** Marks column col as merged; its copy at flat index rightIdx is hidden from "*". */
    Layout merging(String col, int rightIdx) {
        Set<String> m = new HashSet<>(merged);
        m.add(Names.norm(col));
        Set<Integer> h = new HashSet<>(hidden);
        h.add(rightIdx);
        return new Layout(sources, m, h, width);
    }

    Column column(int flat) {
        for (Source s : sources) {
            if (flat < s.offset() + s.columns().size()) return s.columns().get(flat - s.offset());
        }
        throw new IllegalArgumentException("no column " + flat);
    }

    Source source(String name) {
        for (Source s : sources) {
            if (s.name() != null && Names.same(s.name(), name)) return s;
        }
        return null;
    }

    private static int indexIn(Source s, String col) {
        for (int i = 0; i < s.columns().size(); i++) {
            if (Names.same(s.columns().get(i).name(), col)) return i;
        }
        return -1;
    }

    /** Flat index of the first source's column col (the "left side" of a USING), or -1. */
    int findFirst(String col) {
        for (Source s : sources) {
            int i = indexIn(s, col);
            if (i >= 0) return s.offset() + i;
        }
        return -1;
    }

    /**
     * Flat index of qualifier.col (qualifier may be null), or -1 if absent. An unqualified name that
     * several sources have is "ambiguous column name" unless USING merged it.
     */
    int find(String qualifier, String col) {
        if (qualifier != null) {
            Source s = source(qualifier);
            int i = s == null ? -1 : indexIn(s, col);
            return i < 0 ? -1 : s.offset() + i;
        }
        int first = -1;
        for (Source s : sources) {
            int i = indexIn(s, col);
            if (i < 0) continue;
            if (first >= 0) {
                if (merged.contains(Names.norm(col))) return first;
                throw new SqlError("ambiguous column name: " + col);
            }
            first = s.offset() + i;
        }
        return first;
    }
}
