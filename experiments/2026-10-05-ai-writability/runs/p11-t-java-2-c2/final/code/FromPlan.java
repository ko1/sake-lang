import java.util.ArrayList;
import java.util.List;

/** The FROM clause of a query, resolved: its sources, the layout of a joined row, and the joins. */
final class FromPlan {
    /** Where the rows of one source come from (a table, or a subquery run once). */
    interface RowSource {
        List<Object[]> rows();
    }

    /** One join: kind, the rows to add, how many columns they bring, and the resolved condition (null: none). */
    record Join(Stmt.JoinKind kind, RowSource source, int width, Expr condition) {}

    private final Scope scope;
    private final RowSource first;
    private final List<Join> joins;

    FromPlan(Scope scope, RowSource first, List<Join> joins) {
        this.scope = scope;
        this.first = first;
        this.joins = joins;
    }

    /** No FROM: one empty row. */
    static FromPlan none() {
        return new FromPlan(new Scope(), () -> List.<Object[]>of(new Object[0]), List.of());
    }

    Scope scope() {
        return scope;
    }

    /** The joined rows; outer is the environment a join condition's correlated names read. */
    List<Object[]> rows(Env outer) {
        List<Object[]> current = first.rows();
        for (Join j : joins) {
            List<Object[]> right = j.source().rows();
            List<Object[]> next = new ArrayList<>();
            for (Object[] l : current) {
                boolean matched = false;
                for (Object[] r : right) {
                    Object[] pair = concat(l, r);
                    if (j.condition() != null
                        && Values.truth(Evaluator.eval(j.condition(), new Env(pair, outer))) != Boolean.TRUE) {
                        continue;
                    }
                    next.add(pair);
                    matched = true;
                }
                if (!matched && j.kind() == Stmt.JoinKind.LEFT) next.add(concat(l, new Object[j.width()]));
            }
            current = next;
        }
        return current;
    }

    private static Object[] concat(Object[] a, Object[] b) {
        Object[] r = new Object[a.length + b.length];
        System.arraycopy(a, 0, r, 0, a.length);
        System.arraycopy(b, 0, r, a.length, b.length);
        return r;
    }
}
