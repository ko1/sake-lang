package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;

/** Recognising aggregate calls (3.2) and deciding what one means where it is written (3.3). */
final class Aggregates {
    private Aggregates() { }

    /** What a call to an aggregate does while binding in some clause. */
    interface Context {
        /** Binds the aggregate call c, written in scope. */
        Node call(Call c, Scope scope);

        /** Called when a name resolves to an alias whose expression holds an aggregate named aggName. */
        default void aliasUse(String aggName) { }
    }

    private static Context rejecting(String callMessage, String aliasMessage) {
        return new Context() {
            @Override
            public Node call(Call c, Scope scope) {
                throw new SqlError(callMessage.formatted(c.name()));
            }

            @Override
            public void aliasUse(String aggName) {
                throw new SqlError(aliasMessage.formatted(aggName));
            }
        };
    }

    static final Context MISUSE = rejecting("misuse of aggregate function %s()", "misuse of aggregate: %s()");
    static final Context IN_GROUP_BY = rejecting("aggregate functions are not allowed in the GROUP BY clause",
        "aggregate functions are not allowed in the GROUP BY clause");
    /** ORDER BY of a query that is not an aggregate query. */
    static final Context IN_PLAIN_ORDER_BY = rejecting("misuse of aggregate: %s()", "misuse of aggregate: %s()");

    private static final Set<String> NAMES = Set.of("count", "sum", "total", "avg", "group_concat");

    /** True if c is an aggregate: one of the names, or max/min with exactly one argument. */
    static boolean isAggregate(Call c) {
        String n = Names.norm(c.name());
        if (n.equals("max") || n.equals("min")) return c.args().size() == 1 && !c.star();
        return NAMES.contains(n);
    }

    /** The first aggregate call in e (outermost, leftmost), or null; a window call's own name does not count. */
    static Call firstAggregate(Expr e) {
        if (e instanceof Call c && isAggregate(c)) return c;
        for (Expr child : Exprs.children(e)) {
            Call r = firstAggregate(child);
            if (r != null) return r;
        }
        return null; // a subquery's aggregates are its own
    }

    /**
     * Collects the distinct aggregate calls of an aggregate query. A bound call reads its result from
     * slot base + index of the extended group row (the representative row followed by the results).
     */
    static final class Collector implements Context {
        private final List<Call> calls = new ArrayList<>();
        private final List<AggregateFunction> functions = new ArrayList<>();

        @Override
        public Node call(Call c, Scope scope) {
            int idx = calls.indexOf(c); // calls written identically are one
            if (idx < 0) {
                Scope inner = scope.withAgg(MISUSE).withWindows(Windows.REJECT); // misuse inside an aggregate's argument
                functions.add(AggregateFunction.bind(c, inner));
                calls.add(c);
                idx = calls.size() - 1;
            }
            int slot = scope.width() + idx;
            return row -> row[slot];
        }

        List<AggregateFunction> functions() {
            return functions;
        }

        /** The only aggregate when it is min or max: its row supplies the bare columns (3.3); else null. */
        AggregateFunction singleExtreme() {
            return functions.size() == 1 && functions.get(0).isExtreme() ? functions.get(0) : null;
        }
    }
}
