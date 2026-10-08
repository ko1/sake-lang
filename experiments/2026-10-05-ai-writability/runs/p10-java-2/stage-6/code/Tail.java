import java.util.ArrayList;
import java.util.List;

/**
 * The trailing ORDER BY / LIMIT / OFFSET of a compound select or recursive WITH table (SPEC 5.1): terms name
 * result columns only.
 */
final class Tail {
    private final int[] columns;
    private final List<Sorting.Term> terms;
    private final LimitClause window;
    private final Resolver.Level level;

    private Tail(int[] columns, List<Sorting.Term> terms, LimitClause window, Resolver.Level level) {
        this.columns = columns;
        this.terms = terms;
        this.window = window;
        this.level = level;
    }

    /**
     * Resolves the terms against the result columns: an integer is the k-th column, a name is looked up in
     * the column names of each simple select in turn (names.get(j) are those of select j).
     */
    static Tail resolve(Catalog catalog, List<Stmt.OrderTerm> order, Expr limit, Expr offset,
                        List<List<String>> names, int width, Resolver outer) {
        int[] columns = new int[order.size()];
        List<Sorting.Term> terms = new ArrayList<>();
        for (int i = 0; i < columns.length; i++) {
            Stmt.OrderTerm term = order.get(i);
            Long ordinal = Planner.ordinalOf(term.expr());
            if (ordinal != null) {
                if (ordinal < 1 || ordinal > width) {
                    throw new SqlError(Planner.ordinalName(i + 1)
                        + " ORDER BY term out of range - should be between 1 and " + width);
                }
                columns[i] = (int) (ordinal - 1);
            } else {
                columns[i] = find(term.expr(), names);
                if (columns[i] < 0) {
                    throw new SqlError(Planner.ordinalName(i + 1) + " ORDER BY term does not match any column in the result set");
                }
            }
            terms.add(new Sorting.Term(term.desc(), term.nullsFirst()));
        }
        Resolver.Level level = new Resolver.Level();
        Resolver noRow = Resolver.forQuery(catalog, new Scope(), outer, level);
        LimitClause window = new LimitClause(limit == null ? null : noRow.resolve(limit),
            offset == null ? null : noRow.resolve(offset));
        return new Tail(columns, terms, window, level);
    }

    /** Column index of a bare name that is a result column's name in some select, else -1. */
    private static int find(Expr e, List<List<String>> names) {
        if (!(e instanceof Expr.Name n) || n.table() != null) return -1;
        for (List<String> list : names) {
            int i = Resolver.findAlias(list, n.name());
            if (i >= 0) return i;
        }
        return -1;
    }

    boolean correlated() {
        return level.correlated;
    }

    /** How many rows must exist before ORDER BY can be skipped and LIMIT applied (all, if there is ORDER BY). */
    long needed(Env outer) {
        return columns.length > 0 ? Long.MAX_VALUE : window.needed(new Env(new Object[0], outer));
    }

    /** Sorts rows, then applies OFFSET and LIMIT. */
    List<Object[]> apply(List<Object[]> rows, Env outer) {
        List<Object[]> sorted = new ArrayList<>(rows);
        if (columns.length > 0) {
            sorted.sort((a, b) -> Sorting.compare(terms, keys(a), keys(b)));
        }
        return window.apply(sorted, new Env(new Object[0], outer));
    }

    private Object[] keys(Object[] row) {
        Object[] k = new Object[columns.length];
        for (int i = 0; i < k.length; i++) k[i] = row[columns[i]];
        return k;
    }
}
