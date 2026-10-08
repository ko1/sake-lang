import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * A resolved SELECT, ready to run: filtering, grouping, projection, DISTINCT, ordering, LIMIT/OFFSET.
 * Built by Planner. A subquery's plan runs against the rows of its enclosing queries (Env); the result
 * of one that reads none of them is kept.
 */
final class SelectPlan {
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
    private final Expr limit;
    private final Expr offset;
    private final Resolver.Level level;
    private List<Object[]> cached;

    SelectPlan(FromPlan from, Expr where, boolean aggregate, List<Aggregates.Spec> specs, List<Expr> groupBy,
               Expr having, boolean distinct, List<Expr> columns, List<String> names, List<ColType> types,
               List<SortKey> sortKeys, Expr limit, Expr offset, Resolver.Level level) {
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
        this.limit = limit;
        this.offset = offset;
        this.level = level;
    }

    int columnCount() {
        return columns.size();
    }

    /** Name of result column i (the alias, or the column's name), or null if it has none. */
    String name(int i) {
        return names.get(i);
    }

    /** Affinity of result column i: its column's type if it is a plain column reference, else null. */
    ColType type(int i) {
        return types.get(i);
    }

    /** The result rows; outer is the environment of the enclosing query (null at the top level). */
    List<Object[]> execute(Env outer) {
        if (level.correlated) return run(outer);
        if (cached == null) cached = run(outer);
        return cached;
    }

    private List<Object[]> run(Env outer) {
        List<Object[]> rows = new ArrayList<>();
        for (Object[] src : from.rows(outer)) {
            if (where == null || Values.truth(Evaluator.eval(where, new Env(src, outer))) == Boolean.TRUE) {
                rows.add(src);
            }
        }
        if (aggregate) rows = Grouping.groups(rows, groupBy, specs, from.scope().width(), outer);

        List<OutRow> result = new ArrayList<>();
        Set<List<String>> seen = new HashSet<>();
        for (Object[] row : rows) {
            Env env = new Env(row, outer);
            if (having != null && Values.truth(Evaluator.eval(having, env)) != Boolean.TRUE) continue;
            Object[] values = new Object[columns.size()];
            for (int i = 0; i < values.length; i++) values[i] = Evaluator.eval(columns.get(i), env);
            if (distinct && !seen.add(Arrays.stream(values).map(Grouping::key).toList())) continue;
            Object[] keys = new Object[sortKeys.size()];
            for (int i = 0; i < keys.length; i++) {
                SortKey k = sortKeys.get(i);
                keys[i] = k.resultIndex() >= 0 ? values[k.resultIndex()] : Evaluator.eval(k.expr(), env);
            }
            result.add(new OutRow(values, keys));
        }
        List<Sorting.Term> terms = sortKeys.stream().map(SortKey::term).toList();
        if (!terms.isEmpty()) result.sort((a, b) -> Sorting.compare(terms, a.keys(), b.keys()));

        Env noRow = new Env(new Object[0], outer);
        long skip = offset == null ? 0 : Math.max(limitValue(offset, noRow), 0);
        long lim = limit == null ? -1 : limitValue(limit, noRow);
        long max = lim < 0 ? Long.MAX_VALUE : lim;
        List<Object[]> out = new ArrayList<>();
        for (long i = skip; i < result.size() && i - skip < max; i++) out.add(result.get((int) i).values());
        return out;
    }

    /** LIMIT / OFFSET operand: evaluated with no row, read as an integer. */
    private static long limitValue(Expr e, Env env) {
        Object v = Evaluator.eval(e, env);
        if (v == null) return 0;
        Object n = Values.toNumber(v);
        return n instanceof Long l ? l : (long) (double) (Double) n;
    }
}
