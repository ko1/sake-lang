import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Queue;
import java.util.Set;

/**
 * A recursive WITH table (SPEC 5.2): rows are taken from a queue seeded by the initial select; each row
 * taken joins the result and is the one row the recursive select sees as the table.
 */
final class RecursivePlan implements QueryPlan {
    /** The table as the recursive select sees it: the one row being expanded. */
    private static final class Current implements QueryPlan {
        private final QueryPlan shape;
        private final List<String> names;
        List<Object[]> rows = List.of();

        Current(QueryPlan shape, List<String> names) {
            this.shape = shape;
            this.names = names;
        }

        @Override public int columnCount() { return shape.columnCount(); }
        @Override public String name(int i) { return names.get(i); }
        @Override public ColType type(int i) { return shape.type(i); }
        @Override public Collation explicitCollation(int i) { return shape.explicitCollation(i); }
        @Override public Collation implicitCollation(int i) { return shape.implicitCollation(i); }
        @Override public boolean correlated() { return false; }
        @Override public List<Object[]> execute(Env outer) { return rows; }
    }

    private final SelectPlan initial;
    private final SelectPlan step;
    private final Current current;
    private final boolean unionAll;
    private final List<Collation> collations;    // as for a compound select
    private final Tail tail;
    private List<Object[]> cached;

    private RecursivePlan(SelectPlan initial, SelectPlan step, Current current, boolean unionAll,
                          List<Collation> collations, Tail tail) {
        this.collations = collations;
        this.initial = initial;
        this.step = step;
        this.current = current;
        this.unionAll = unionAll;
        this.tail = tail;
    }

    /** The WITH table entry for cte (whose select is `initial UNION [ALL] recursive`). */
    static Catalog.Cte plan(Catalog catalog, Stmt.Cte cte) {
        Stmt.Select s = cte.select();
        Stmt.CompoundPart part = s.rest().get(0);
        SelectPlan initial = Planner.planSimple(catalog, s.first(), List.of(), null, null, null);
        List<String> names = Planner.columnNames(cte.name(), initial, cte.columns());
        Current current = new Current(initial, names);
        Catalog inner = catalog.withCte(cte.name(), new Catalog.Cte(current, names));
        SelectPlan step = Planner.planSimple(inner, part.select(), List.of(), null, null, null);
        CompoundPlan.checkWidths(List.of(initial, step), List.of(part.op()));
        List<Collation> collations = CompoundPlan.columnCollations(List.of(initial, step));
        Tail tail = Tail.resolve(catalog, s.orderBy(), s.limit(), s.offset(), List.of(names), collations, null);
        RecursivePlan plan = new RecursivePlan(initial, step, current, part.op() == Stmt.CompoundOp.UNION_ALL,
            collations, tail);
        return new Catalog.Cte(plan, names);
    }

    @Override
    public int columnCount() {
        return initial.columnCount();
    }

    @Override
    public String name(int i) {
        return current.name(i);
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
        return false;
    }

    @Override
    public List<Object[]> execute(Env outer) {
        if (cached == null) cached = run();
        return cached;
    }

    private List<Object[]> run() {
        Queue<Object[]> queue = new ArrayDeque<>();
        Set<List<String>> queued = unionAll ? null : new HashSet<>();
        long needed = tail.needed(null);
        enqueue(queue, queued, initial.execute(null), collations);
        List<Object[]> result = new ArrayList<>();
        while (!queue.isEmpty() && result.size() < needed) {
            Object[] row = queue.poll();
            result.add(row);
            current.rows = java.util.Collections.singletonList(row);
            enqueue(queue, queued, step.executeFresh(null), collations);
        }
        current.rows = List.of();
        return tail.apply(result, null);
    }

    /** Appends rows to the queue; without UNION ALL, a row equal to one queued before is dropped. */
    private static void enqueue(Queue<Object[]> queue, Set<List<String>> queued, List<Object[]> rows,
                                List<Collation> colls) {
        for (Object[] row : rows) {
            if (queued == null || queued.add(Grouping.rowKey(row, colls))) queue.add(row);
        }
    }
}
