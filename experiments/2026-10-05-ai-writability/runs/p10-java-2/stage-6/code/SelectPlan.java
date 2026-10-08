import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * A resolved SELECT, ready to run: filtering, grouping, window functions, projection, DISTINCT, ordering, LIMIT/OFFSET.
 * Built by Planner. A subquery's plan runs against the rows of its enclosing queries (Env); the result
 * of one that reads none of them is kept.
 */
final class SelectPlan implements QueryPlan {
    /** One ORDER BY term: either a result column (resultIndex >= 0) or an expression over the row. */
    record SortKey(int resultIndex, Expr expr, Sorting.Term term) {}

    private record OutRow(Object[] values, Object[] keys) {}

    private final FromPlan from;
    private final Expr where;
    private final boolean aggregate;
    private final List<Aggregates.Spec> specs;
    private final List<Expr> groupBy;
    private final Expr having;
    private final boolean distinct;
    private final List<Expr> columns;
    private final List<String> names;
    private final List<ColType> types;
    private final List<SortKey> sortKeys;
    private final LimitClause window;
    private final List<Windows.Call> windows;
    private final Resolver.Level level;
    private List<Object[]> cached;

    SelectPlan(FromPlan from, Expr where, boolean aggregate, List<Aggregates.Spec> specs, List<Expr> groupBy,
               Expr having, boolean distinct, List<Expr> columns, List<String> names, List<ColType> types,
               List<SortKey> sortKeys, LimitClause window, List<Windows.Call> windows, Resolver.Level level) {
        this.from = from;
        this.where = where;
        this.aggregate = aggregate;
        this.specs = specs;
        this.groupBy = groupBy;
        this.having = having;
        this.distinct = distinct;
        this.columns = columns;
        this.names = names;
        this.types = types;
        this.sortKeys = sortKeys;
        this.window = window;
        this.windows = windows;
        this.level = level;
    }

    @Override
    public int columnCount() {
        return columns.size();
    }

    @Override
    public String name(int i) {
        return names.get(i);
    }

    @Override
    public ColType type(int i) {
        return types.get(i);
    }

    @Override
    public boolean correlated() {
        return level.correlated;
    }

    @Override
    public List<Object[]> execute(Env outer) {
        if (level.correlated) return run(outer);
        if (cached == null) cached = run(outer);
        return cached;
    }

    /** Runs the query now, ignoring the kept result (for a plan whose source changes between runs). */
    List<Object[]> executeFresh(Env outer) {
        return run(outer);
    }

    private List<Object[]> run(Env outer) {
        List<Object[]> rows = new ArrayList<>();
        for (Object[] src : from.rows(outer)) {
            if (where == null || Values.truth(Evaluator.eval(where, new Env(src, outer))) == Boolean.TRUE) {
                rows.add(src);
            }
        }
        if (aggregate) rows = Grouping.groups(rows, groupBy, specs, from.scope().width(), outer);

        if (having != null) {
            List<Object[]> kept = new ArrayList<>();
            for (Object[] row : rows) {
                if (Values.truth(Evaluator.eval(having, new Env(row, outer))) == Boolean.TRUE) kept.add(row);
            }
            rows = kept;
        }
        rows = Windows.extend(windows, rows, outer);

        List<OutRow> result = new ArrayList<>();
        Set<List<String>> seen = new HashSet<>();
        for (Object[] row : rows) {
            Env env = new Env(row, outer);
            Object[] values = new Object[columns.size()];
            for (int i = 0; i < values.length; i++) values[i] = Evaluator.eval(columns.get(i), env);
            if (distinct && !seen.add(Grouping.rowKey(values))) continue;
            Object[] keys = new Object[sortKeys.size()];
            for (int i = 0; i < keys.length; i++) {
                SortKey k = sortKeys.get(i);
                keys[i] = k.resultIndex() >= 0 ? values[k.resultIndex()] : Evaluator.eval(k.expr(), env);
            }
            result.add(new OutRow(values, keys));
        }
        List<Sorting.Term> terms = sortKeys.stream().map(SortKey::term).toList();
        if (!terms.isEmpty()) result.sort((a, b) -> Sorting.compare(terms, a.keys(), b.keys()));

        List<Object[]> out = new ArrayList<>();
        for (OutRow r : window.apply(result, new Env(new Object[0], outer))) out.add(r.values());
        return out;
    }
}
