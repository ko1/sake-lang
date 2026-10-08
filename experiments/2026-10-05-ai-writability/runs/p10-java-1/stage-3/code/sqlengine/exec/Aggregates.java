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

    /** The first aggregate call in e (outermost, leftmost), or null. */
    static Call firstAggregate(Expr e) {
        if (e instanceof Call c) {
            if (isAggregate(c)) return c;
            for (Expr a : c.args()) {
                Call r = firstAggregate(a);
                if (r != null) return r;
            }
            return null;
        }
        if (e instanceof Unary u) return firstAggregate(u.operand());
        if (e instanceof Binary b) return first(b.left(), b.right());
        if (e instanceof Is i) return first(i.left(), i.right());
        if (e instanceof Between b) return first(b.value(), b.low(), b.high());
        if (e instanceof Like l) return first(l.value(), l.pattern());
        if (e instanceof Cast c) return firstAggregate(c.value());
        if (e instanceof In in) {
            List<Expr> all = new ArrayList<>();
            all.add(in.value());
            all.addAll(in.items());
            return first(all.toArray(Expr[]::new));
        }
        if (e instanceof Case c) {
            List<Expr> all = new ArrayList<>();
            if (c.operand() != null) all.add(c.operand());
            for (When w : c.whens()) {
                all.add(w.condition());
                all.add(w.result());
            }
            if (c.elseResult() != null) all.add(c.elseResult());
            return first(all.toArray(Expr[]::new));
        }
        return null; // Literal, Name
    }

    private static Call first(Expr... es) {
        for (Expr e : es) {
            Call r = firstAggregate(e);
            if (r != null) return r;
        }
        return null;
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
                Scope inner = scope.withAgg(MISUSE); // an aggregate inside an aggregate's argument is misuse
                functions.add(AggregateFunction.bind(c, inner));
                calls.add(c);
                idx = calls.size() - 1;
            }
            int slot = scope.columns().size() + idx;
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
