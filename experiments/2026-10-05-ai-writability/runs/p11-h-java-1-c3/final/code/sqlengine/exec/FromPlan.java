package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.SqlType;
import sqlengine.value.Values;

/**
 * A compiled FROM (4.1): the layout of the joined row and the join steps that produce its rows.
 * Joins associate to the left and are nested loops.
 */
final class FromPlan {
    /** A source's rows: a table's stored rows, or a subquery's result, computed when asked. */
    private record Input(Supplier<List<Object[]>> rows, int width) { }

    /** One join step; on is null for a cross join. */
    private record Step(JoinKind kind, Input right, Node on) { }

    private final Input first;
    private final List<Step> steps;
    private final Layout layout;

    private FromPlan(Input first, List<Step> steps, Layout layout) {
        this.first = first;
        this.steps = steps;
        this.layout = layout;
    }

    /** The plan of "no FROM": one empty row. */
    static FromPlan none() {
        return new FromPlan(new Input(() -> List.<Object[]>of(new Object[0]), 0), List.of(), Layout.EMPTY);
    }

    Layout layout() {
        return layout;
    }

    /** Compiles from in the context of scope (only its db, outer scope and frame are used). */
    static FromPlan compile(FromClause from, Scope scope) {
        Layout layout = Layout.EMPTY;
        Input firstInput = null;
        List<Step> steps = new ArrayList<>();
        for (int n = -1; n < from.joins().size(); n++) {
            FromItem item = n < 0 ? from.first() : from.joins().get(n).item();
            String name;
            List<Column> columns;
            boolean rowid = false;
            Supplier<List<Object[]>> rows;
            if (item instanceof TableRef tr) {
                Relation rel = resolve(tr.table(), scope);
                name = tr.alias() != null ? tr.alias() : tr.table();
                columns = rel.columns();
                rows = rel.rows();
                rowid = rel.rowid();
            } else {
                SubqueryRef sr = (SubqueryRef) item;
                Query q = QueryCompiler.compile(scope.db(), scope.ctes(), sr.select(), null);
                name = sr.alias();
                columns = q.outputs();
                rows = q::run;
            }
            Input input = new Input(rows, columns.size() + (rowid ? 1 : 0));
            if (n < 0) {
                firstInput = input;
                layout = layout.plus(name, columns, rowid);
                continue;
            }
            JoinStep js = from.joins().get(n);
            Layout before = layout;
            layout = layout.plus(name, columns, rowid);
            Node on = null;
            if (!js.using().isEmpty()) {
                on = usingCondition(before, layout, js.using());
                for (String c : js.using()) layout = layout.merging(c, before.width() + indexOf(columns, c));
            } else if (js.on() != null) {
                on = Binder.bind(js.on(), scope.withLayout(layout));
            }
            steps.add(new Step(js.kind(), input, on));
        }
        return new FromPlan(firstInput, steps, layout);
    }

    /** What a table name in FROM means: a cte, else a view, else a table (5.2, 5.3). */
    private static Relation resolve(String name, Scope scope) {
        Relation cte = scope.ctes().find(name);
        if (cte != null) return cte;
        Database db = scope.db();
        View view = db.findView(name);
        if (view != null) return view.open(db);
        Table t = db.require(name);
        return new Relation(t.columns, t::rows, true);
    }

    private static int indexOf(List<Column> columns, String name) {
        for (int i = 0; i < columns.size(); i++) {
            if (sqlengine.value.Names.same(columns.get(i).name(), name)) return i;
        }
        return -1;
    }

    /** USING (c, ...) as ON left.c = right.c AND ...; left is the layout before the right source. */
    private static Node usingCondition(Layout left, Layout all, List<String> names) {
        int n = names.size();
        int[] l = new int[n];
        int[] r = new int[n];
        SqlType[] la = new SqlType[n];
        SqlType[] ra = new SqlType[n];
        Source right = all.sources().get(all.sources().size() - 1);
        for (int k = 0; k < n; k++) {
            int ri = indexOf(right.columns(), names.get(k));
            int li = left.findFirst(names.get(k));
            if (ri < 0 || li < 0) {
                throw new SqlError("cannot join using column " + names.get(k) + " - column not present in both tables");
            }
            l[k] = li;
            r[k] = right.offset() + ri;
            la[k] = all.column(li).type();
            ra[k] = all.column(r[k]).type();
        }
        return row -> {
            Object result = 1L;
            for (int k = 0; k < n; k++) {
                result = Operators.and(result, Operators.compare("=", row[l[k]], la[k], row[r[k]], ra[k]));
            }
            return result;
        };
    }

    /** All joined rows. */
    List<Object[]> rows() {
        List<Object[]> acc = first.rows().get();
        for (Step step : steps) {
            List<Object[]> right = step.right().rows().get();
            List<Object[]> out = new ArrayList<>();
            for (Object[] l : acc) {
                boolean matched = false;
                for (Object[] r : right) {
                    Object[] row = concat(l, r);
                    if (step.on() == null || Boolean.TRUE.equals(Values.truth(step.on().eval(row)))) {
                        out.add(row);
                        matched = true;
                    }
                }
                if (!matched && step.kind() == JoinKind.LEFT) out.add(concat(l, new Object[step.right().width()]));
            }
            acc = out;
        }
        return acc;
    }

    private static Object[] concat(Object[] a, Object[] b) {
        Object[] row = new Object[a.length + b.length];
        System.arraycopy(a, 0, row, 0, a.length);
        System.arraycopy(b, 0, row, a.length, b.length);
        return row;
    }
}
