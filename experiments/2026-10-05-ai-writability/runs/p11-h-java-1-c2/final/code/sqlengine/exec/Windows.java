package sqlengine.exec;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.NamedWindow;
import sqlengine.parse.Ast.WindowCall;
import sqlengine.parse.Ast.WindowSpec;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;

/** Window calls while binding (6.1, 6.2): where one may be written, named windows, and the slots results go to. */
final class Windows {
    private Windows() { }

    /** What a window call does while binding in some clause. */
    interface Context {
        /** Binds the window call w, written in scope. */
        Node call(WindowCall w, Scope scope);

        /** Called when a name resolves to the alias of a result column that holds a window call. */
        void aliasUse(String alias);
    }

    /** Every clause except the result columns and ORDER BY of a SELECT (and anything inside a window or aggregate call). */
    static final Context REJECT = new Context() {
        @Override
        public Node call(WindowCall w, Scope scope) {
            throw misuse(w.call().name());
        }

        @Override
        public void aliasUse(String alias) {
            throw new SqlError("misuse of aliased window function " + alias);
        }
    };

    static SqlError misuse(String name) {
        return new SqlError("misuse of window function " + name + "()");
    }

    static boolean isWindowOnly(String name) {
        return WindowFunctions.isWindowOnly(name);
    }

    /**
     * The window calls of one simple select. A bound call reads its result from a slot after the row's
     * columns and aggregate results; apply() appends those slots to every row.
     */
    static final class Collector implements Context {
        private final Aggregates.Collector aggs;
        private final int width;
        private final Map<String, WindowSpec> named = new HashMap<>();
        private final List<WindowCall> calls = new ArrayList<>();
        private final List<WindowComputation> computations = new ArrayList<>();

        /** width is the source row's width; named is the select's WINDOW clause. */
        Collector(Aggregates.Collector aggs, int width, List<NamedWindow> windows) {
            this.aggs = aggs;
            this.width = width;
            for (NamedWindow w : windows) {
                if (named.put(Names.norm(w.name()), w.spec()) != null) {
                    throw new SqlError("duplicate WINDOW name: " + w.name());
                }
            }
            for (NamedWindow w : windows) resolve(w.spec());
        }

        boolean isEmpty() {
            return computations.isEmpty();
        }

        @Override
        public Node call(WindowCall w, Scope scope) {
            int idx = calls.indexOf(w); // calls written identically are one
            if (idx < 0) {
                Scope inner = scope.withAliases(null).withWindows(REJECT);
                computations.add(WindowComputation.bind(w.call(), resolve(w.spec()), inner));
                calls.add(w);
                idx = calls.size() - 1;
            }
            int i = idx;
            return row -> row[firstSlot() + i];
        }

        @Override
        public void aliasUse(String alias) { }

        /** The extended row's first window slot; read late because later clauses may add aggregates. */
        private int firstSlot() {
            return width + aggs.functions().size();
        }

        /** spec with its base window (6.1) filled in: what it lacks it takes from the base. */
        private WindowSpec resolve(WindowSpec spec) {
            return resolve(spec, 0);
        }

        private WindowSpec resolve(WindowSpec spec, int depth) {
            if (spec.base() == null) return spec;
            WindowSpec base = named.get(Names.norm(spec.base()));
            if (base == null || depth > named.size()) throw new SqlError("no such window: " + spec.base());
            base = resolve(base, depth + 1);
            return new WindowSpec(null,
                spec.partitionBy().isEmpty() ? base.partitionBy() : spec.partitionBy(),
                spec.orderBy().isEmpty() ? base.orderBy() : spec.orderBy(),
                spec.frame() != null ? spec.frame() : base.frame());
        }

        /** rows extended by one slot per window call, each filled in. */
        List<Object[]> apply(List<Object[]> rows) {
            int first = firstSlot();
            List<Object[]> out = new ArrayList<>(rows.size());
            for (Object[] row : rows) out.add(Arrays.copyOf(row, first + computations.size()));
            for (int i = 0; i < computations.size(); i++) computations.get(i).run(out, first + i);
            return out;
        }
    }
}
