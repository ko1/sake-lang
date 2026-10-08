import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** A compound select (UNION / UNION ALL / INTERSECT / EXCEPT, SPEC 5.1): simple selects combined left to right. */
final class CompoundPlan implements QueryPlan {
    private final List<SelectPlan> parts;
    private final List<Stmt.CompoundOp> ops;     // ops.get(i) joins parts.get(i + 1) to what is on its left
    private final List<Collation> collations;    // per column: the first part's that has one, else BINARY
    private final Tail tail;
    private List<Object[]> cached;

    private CompoundPlan(List<SelectPlan> parts, List<Stmt.CompoundOp> ops, List<Collation> collations, Tail tail) {
        this.parts = parts;
        this.ops = ops;
        this.collations = collations;
        this.tail = tail;
    }

    /** Plans the parts of q (the WITH tables are already in catalog) and checks their column counts. */
    static CompoundPlan plan(Catalog catalog, Stmt.Select q, Resolver outer) {
        List<SelectPlan> parts = new ArrayList<>();
        List<Stmt.CompoundOp> ops = new ArrayList<>();
        parts.add(Planner.planSimple(catalog, q.first(), List.of(), null, null, outer));
        for (Stmt.CompoundPart part : q.rest()) {
            parts.add(Planner.planSimple(catalog, part.select(), List.of(), null, null, outer));
            ops.add(part.op());
        }
        checkWidths(parts, ops);
        List<List<String>> names = new ArrayList<>();
        for (SelectPlan p : parts) names.add(namesOf(p));
        List<Collation> collations = columnCollations(parts);
        Tail tail = Tail.resolve(catalog, q.orderBy(), q.limit(), q.offset(), names, collations, outer);
        return new CompoundPlan(parts, ops, collations, tail);
    }

    /** Column k's collation (SPEC 7.4): that of the first part whose k-th column has one, else BINARY. */
    static List<Collation> columnCollations(List<? extends QueryPlan> parts) {
        List<Collation> out = new ArrayList<>();
        for (int k = 0; k < parts.get(0).columnCount(); k++) {
            Collation found = null;
            for (QueryPlan p : parts) {
                found = p.collation(k);
                if (found != null) break;
            }
            out.add(found != null ? found : Collation.BINARY);
        }
        return out;
    }

    /** Every part must be as wide as the first; the error names the operator where it is found. */
    static void checkWidths(List<? extends QueryPlan> parts, List<Stmt.CompoundOp> ops) {
        for (int i = 1; i < parts.size(); i++) {
            if (parts.get(i).columnCount() != parts.get(0).columnCount()) {
                throw new SqlError("SELECTs to the left and right of " + ops.get(i - 1).sql
                    + " do not have the same number of result columns");
            }
        }
    }

    static List<String> namesOf(QueryPlan p) {
        List<String> names = new ArrayList<>();
        for (int i = 0; i < p.columnCount(); i++) names.add(p.name(i));
        return names;
    }

    @Override
    public int columnCount() {
        return parts.get(0).columnCount();
    }

    @Override
    public String name(int i) {
        return parts.get(0).name(i);
    }

    @Override
    public ColType type(int i) {
        return null;
    }

    @Override
    public Collation explicitCollation(int i) {
        return null;
    }

    @Override
    public Collation implicitCollation(int i) {
        return collations.get(i);
    }

    @Override
    public boolean correlated() {
        return tail.correlated() || parts.stream().anyMatch(SelectPlan::correlated);
    }

    @Override
    public List<Object[]> execute(Env outer) {
        if (correlated()) return run(outer);
        if (cached == null) cached = run(outer);
        return cached;
    }

    private List<Object[]> run(Env outer) {
        List<Object[]> rows = parts.get(0).execute(outer);
        for (int i = 0; i < ops.size(); i++) rows = combine(ops.get(i), rows, parts.get(i + 1).execute(outer), collations);
        return tail.apply(rows, outer);
    }

    private static List<Object[]> combine(Stmt.CompoundOp op, List<Object[]> left, List<Object[]> right,
                                          List<Collation> colls) {
        List<Object[]> out = new ArrayList<>();
        switch (op) {
            case UNION_ALL -> {
                out.addAll(left);
                out.addAll(right);
            }
            case UNION -> {
                Set<List<String>> seen = new HashSet<>();
                for (List<Object[]> side : List.of(left, right)) {
                    for (Object[] row : side) if (seen.add(Grouping.rowKey(row, colls))) out.add(row);
                }
            }
            case INTERSECT, EXCEPT -> {
                Set<List<String>> other = new HashSet<>();
                for (Object[] row : right) other.add(Grouping.rowKey(row, colls));
                boolean keepMatches = op == Stmt.CompoundOp.INTERSECT;
                Map<List<String>, Object[]> distinct = new LinkedHashMap<>();
                for (Object[] row : left) {
                    List<String> k = Grouping.rowKey(row, colls);
                    if (other.contains(k) == keepMatches) distinct.putIfAbsent(k, row);
                }
                out.addAll(distinct.values());
            }
        }
        return out;
    }
}
