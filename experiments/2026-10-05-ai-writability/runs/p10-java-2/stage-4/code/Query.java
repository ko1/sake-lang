/** Runs a top-level SELECT: plans it, runs the plan, and appends one line per result row to out. */
final class Query {
    private final Catalog catalog;
    private final StringBuilder out;

    Query(Catalog catalog, StringBuilder out) {
        this.catalog = catalog;
        this.out = out;
    }

    void run(Stmt.Select q) {
        SelectPlan plan = Planner.plan(catalog, q, null);
        for (Object[] values : plan.execute(null)) {
            for (int c = 0; c < values.length; c++) {
                if (c > 0) out.append('|');
                out.append(Values.display(values[c]));
            }
            out.append('\n');
        }
    }
}
