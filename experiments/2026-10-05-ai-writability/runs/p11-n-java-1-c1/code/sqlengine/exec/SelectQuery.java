package sqlengine.exec;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import sqlengine.value.Collation;
import sqlengine.value.Values;

/** A compiled simple SELECT, with its own ORDER BY / LIMIT when it is a whole select (1.7, 3.3, 4.1). */
final class SelectQuery implements Query {
    /** An ORDER BY term resolved to either a result column or an expression on the evaluation row. */
    record SortKey(int resultIndex, Node node, Ordering.Key order) { }

    private final List<Column> outputs;
    private final FromPlan from;
    private final Node where;
    private final boolean aggregate;
    private final List<Node> groupBy;
    private final Collation[] groupColls;
    private final Node having;
    private final Aggregates.Collector collector;
    private final Windows.Collector windows;
    private final List<Node> results;
    private final boolean distinct;
    private final Collation[] distinctColls;
    private final List<SortKey> keys;
    private final long limit;
    private final long offset;

    SelectQuery(List<Column> outputs, FromPlan from, Node where, boolean aggregate, List<Node> groupBy, Node having,
          Aggregates.Collector collector, Windows.Collector windows, List<Node> results, boolean distinct,
          List<SortKey> keys, long limit, long offset) {
        this.outputs = outputs;
        this.from = from;
        this.where = where;
        this.aggregate = aggregate;
        this.groupBy = groupBy;
        this.groupColls = RowSets.collationsOf(groupBy);
        this.having = having;
        this.collector = collector;
        this.windows = windows;
        this.results = results;
        this.distinct = distinct;
        this.distinctColls = RowSets.collationsOf(results);
        this.keys = keys;
        this.limit = limit;
        this.offset = offset;
    }

    @Override
    public List<Column> outputs() {
        return outputs;
    }

    @Override
    public List<Object[]> run() {
        List<Object[]> rows = new ArrayList<>();
        for (Object[] row : from.rows()) {
            if (where == null || Boolean.TRUE.equals(Values.truth(where.eval(row)))) rows.add(row);
        }
        if (aggregate) rows = groupRows(rows);
        if (!windows.isEmpty()) rows = windows.apply(rows); // 6.2: after grouping, before DISTINCT / ORDER BY / LIMIT

        List<Ordering.Key> orders = keys.stream().map(SortKey::order).toList();
        Set<List<Object>> seen = new HashSet<>();
        List<Object[][]> produced = new ArrayList<>(); // {result values, sort keys}
        for (Object[] row : rows) {
            Object[] vals = new Object[results.size()];
            for (int i = 0; i < vals.length; i++) vals[i] = results.get(i).eval(row);
            if (distinct && !seen.add(RowSets.key(vals, distinctColls))) continue;
            Object[] ks = new Object[keys.size()];
            for (int i = 0; i < ks.length; i++) {
                SortKey k = keys.get(i);
                ks[i] = k.resultIndex() >= 0 ? vals[k.resultIndex()] : k.node().eval(row);
            }
            produced.add(new Object[][] {vals, ks});
        }
        if (!keys.isEmpty()) produced.sort((a, b) -> Ordering.compare(orders, a[1], b[1]));

        long end = limit < 0 ? Long.MAX_VALUE : offset + limit;
        List<Object[]> out = new ArrayList<>();
        for (long i = offset; i < produced.size() && i < end; i++) out.add(produced.get((int) i)[0]);
        return out;
    }

    /**
     * Partitions rows by the GROUP BY values (3.3) and returns one extended row per group kept by HAVING:
     * the representative row followed by the group's aggregate results, where Collector's slots read them.
     */
    private List<Object[]> groupRows(List<Object[]> rows) {
        int width = from.layout().width();
        Map<List<Object>, List<Object[]>> groups = new LinkedHashMap<>();
        if (groupBy.isEmpty()) {
            groups.put(List.of(), rows); // the single group exists even without rows
        } else {
            for (Object[] row : rows) {
                Object[] key = new Object[groupBy.size()];
                for (int i = 0; i < key.length; i++) key[i] = groupBy.get(i).eval(row);
                groups.computeIfAbsent(RowSets.key(key, groupColls), k -> new ArrayList<>()).add(row);
            }
        }
        List<AggregateFunction> functions = collector.functions();
        AggregateFunction extreme = collector.singleExtreme();
        List<Object[]> result = new ArrayList<>();
        for (List<Object[]> group : groups.values()) {
            Object[] rep = group.isEmpty() ? new Object[width] : group.get(0);
            if (extreme != null) {
                Object[] r = extreme.extremeRow(group);
                if (r != null) rep = r;
            }
            Object[] ext = Arrays.copyOf(rep, width + functions.size());
            for (int i = 0; i < functions.size(); i++) ext[width + i] = functions.get(i).compute(group);
            if (having == null || Boolean.TRUE.equals(Values.truth(having.eval(ext)))) result.add(ext);
        }
        return result;
    }
}
