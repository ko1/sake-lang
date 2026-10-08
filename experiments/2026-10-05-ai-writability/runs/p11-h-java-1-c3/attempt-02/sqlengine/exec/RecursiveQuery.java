package sqlengine.exec;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;

/** The select of a recursive cte: initial UNION [ALL] recursive, computed with a queue (5.2). */
final class RecursiveQuery implements Query {
    /** The row the recursive select sees as the cte while it runs. */
    private static final class Current {
        List<Object[]> rows = List.of();
    }

    private final List<Column> columns;
    private final Query initial;
    private final Query step;
    private final Current current;
    private final boolean dedupe;
    private final long limit;
    private final long offset;

    private RecursiveQuery(List<Column> columns, Query initial, Query step, Current current, boolean dedupe,
                           long limit, long offset) {
        this.columns = columns;
        this.initial = initial;
        this.step = step;
        this.current = current;
        this.dedupe = dedupe;
        this.limit = limit;
        this.offset = offset;
    }

    /** True if cte is "initial UNION [ALL] recursive" with the recursive part's FROM naming the cte. */
    static boolean isRecursive(Cte cte) {
        List<CompoundTerm> rest = cte.select().rest();
        if (rest.isEmpty()) return false;
        CompoundTerm last = rest.get(rest.size() - 1);
        if (last.op() != CompoundOp.UNION && last.op() != CompoundOp.UNION_ALL) return false;
        FromClause from = last.select().from();
        if (from == null) return false;
        if (names(from.first(), cte.name())) return true;
        return from.joins().stream().anyMatch(j -> names(j.item(), cte.name()));
    }

    private static boolean names(FromItem item, String cte) {
        return item instanceof TableRef t && Names.same(t.table(), cte);
    }

    /** Compiles cte (for which isRecursive holds); before holds the ctes defined ahead of it. */
    static Query compile(Database db, Ctes before, Cte cte) {
        Select sel = cte.select();
        List<CompoundTerm> rest = sel.rest();
        CompoundTerm last = rest.get(rest.size() - 1);
        Select initialSelect = new Select(null, sel.first(), rest.subList(0, rest.size() - 1), List.of(), null, null);
        Query initial = QueryCompiler.compile(db, before, initialSelect, null);
        List<Column> columns = Relation.of(initial, cte.columns(), "table " + cte.name()).columns();
        Current current = new Current();
        Ctes inner = before.plus(cte.name(), () -> new Relation(columns, () -> current.rows, false));
        Select stepSelect = new Select(null, last.select(), List.of(), List.of(), null, null);
        Query step = QueryCompiler.compile(db, inner, stepSelect, null);
        if (step.outputs().size() != columns.size()) {
            throw new SqlError("SELECTs to the left and right of " + last.op().text
                + " do not have the same number of result columns");
        }
        long[] window = QueryCompiler.window(db, before, sel);
        return new RecursiveQuery(columns, initial, step, current, last.op() == CompoundOp.UNION,
            window[0], window[1]);
    }

    @Override
    public List<Column> outputs() {
        return columns;
    }

    @Override
    public List<Object[]> run() {
        List<Object[]> result = new ArrayList<>();
        Deque<Object[]> queue = new ArrayDeque<>();
        Set<List<Object>> queued = dedupe ? new HashSet<>() : null;
        long cap = limit < 0 ? Long.MAX_VALUE : offset + limit; // a LIMIT stops the computation early
        for (Object[] r : initial.run()) enqueue(queue, queued, r);
        while (!queue.isEmpty() && result.size() < cap) {
            Object[] row = queue.poll();
            result.add(row);
            current.rows = List.<Object[]>of(row);
            for (Object[] r : step.run()) enqueue(queue, queued, r);
        }
        current.rows = List.of();
        List<Object[]> out = new ArrayList<>();
        for (long i = offset; i < result.size() && i < cap; i++) out.add(result.get((int) i));
        return out;
    }

    private static void enqueue(Deque<Object[]> queue, Set<List<Object>> queued, Object[] row) {
        if (queued == null || queued.add(RowSets.key(row))) queue.add(row);
    }
}
