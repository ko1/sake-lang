package sqlengine.exec;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import sqlengine.parse.Ast.CompoundOp;
import sqlengine.value.Collation;

/** simple-select (UNION | UNION ALL | INTERSECT | EXCEPT simple-select)... with ORDER BY / LIMIT on the whole (5.1). */
final class CompoundQuery implements Query {
    /** An ORDER BY term: the result column it names, and its direction. */
    record SortKey(int column, Ordering.Key order) { }

    private final Query first;
    private final List<CompoundOp> ops;
    private final List<Query> rest;
    private final List<SortKey> keys;
    private final long limit;
    private final long offset;
    private final Collation[] collations;

    CompoundQuery(Query first, List<CompoundOp> ops, List<Query> rest, List<SortKey> keys, long limit, long offset) {
        this.first = first;
        this.ops = ops;
        this.rest = rest;
        this.keys = keys;
        this.limit = limit;
        this.offset = offset;
        List<Query> all = new ArrayList<>(rest);
        all.add(0, first);
        this.collations = merge(all);
    }

    /**
     * The collation of each column of a compound (7.4): that of the first part, left to right, whose
     * column has one (null entries: none, so BINARY).
     */
    static Collation[] merge(List<Query> parts) {
        Collation[] merged = new Collation[parts.get(0).outputs().size()];
        for (Query part : parts) {
            Collation[] c = part.collations();
            for (int k = 0; k < merged.length; k++) {
                if (merged[k] == null) merged[k] = c[k];
            }
        }
        return merged;
    }

    @Override
    public List<Node> resultNodes() {
        return first.resultNodes();
    }

    @Override
    public Collation[] collations() {
        return collations;
    }

    @Override
    public List<Column> outputs() {
        return first.outputs();
    }

    @Override
    public List<Object[]> run() {
        List<Object[]> rows = first.run();
        for (int i = 0; i < ops.size(); i++) rows = combine(ops.get(i), rows, rest.get(i).run(), collations);
        if (!keys.isEmpty()) {
            List<Ordering.Key> orders = keys.stream().map(SortKey::order).toList();
            List<Object[]> sorted = new ArrayList<>(rows);
            sorted.sort((a, b) -> Ordering.compare(orders, sortValues(a), sortValues(b)));
            rows = sorted;
        }
        long end = limit < 0 ? Long.MAX_VALUE : offset + limit;
        List<Object[]> out = new ArrayList<>();
        for (long i = offset; i < rows.size() && i < end; i++) out.add(rows.get((int) i));
        return out;
    }

    private Object[] sortValues(Object[] row) {
        Object[] vals = new Object[keys.size()];
        for (int i = 0; i < vals.length; i++) vals[i] = row[keys.get(i).column()];
        return vals;
    }

    private static List<Object[]> combine(CompoundOp op, List<Object[]> left, List<Object[]> right,
                                          Collation[] collations) {
        List<Object[]> out = new ArrayList<>();
        if (op == CompoundOp.UNION_ALL) {
            out.addAll(left);
            out.addAll(right);
            return out;
        }
        Set<List<Object>> seen = new HashSet<>();
        if (op == CompoundOp.UNION) {
            for (Object[] r : left) if (seen.add(RowSets.key(r, collations))) out.add(r);
            for (Object[] r : right) if (seen.add(RowSets.key(r, collations))) out.add(r);
            return out;
        }
        Set<List<Object>> other = new HashSet<>();
        for (Object[] r : right) other.add(RowSets.key(r, collations));
        boolean keepCommon = op == CompoundOp.INTERSECT;
        for (Object[] r : left) {
            List<Object> k = RowSets.key(r, collations);
            if (other.contains(k) == keepCommon && seen.add(k)) out.add(r);
        }
        return out;
    }
}
