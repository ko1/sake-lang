import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** WITH (SPEC 5.2): turns the tables of a WITH clause into entries of a Catalog overlay. */
final class Ctes {
    private Ctes() {}

    /** The catalog the statement's select sees: catalog plus the WITH tables, each visible to the ones after it. */
    static Catalog bind(Catalog catalog, Stmt.With with) {
        Set<String> names = new HashSet<>();
        for (Stmt.Cte cte : with.ctes()) {
            if (!names.add(Table.key(cte.name()))) throw new SqlError("duplicate WITH table name: " + cte.name());
        }
        Catalog current = catalog;
        for (Stmt.Cte cte : with.ctes()) {
            Catalog.Cte entry = with.recursive() && isRecursive(cte)
                ? RecursivePlan.plan(current, cte)
                : plain(current, cte);
            current = current.withCte(cte.name(), entry);
        }
        return current;
    }

    private static Catalog.Cte plain(Catalog catalog, Stmt.Cte cte) {
        QueryPlan plan = Planner.plan(catalog, cte.select(), null);
        return new Catalog.Cte(plan, Planner.columnNames(cte.name(), plan, cte.columns()));
    }

    /** `initial UNION [ALL] recursive` where recursive's FROM mentions the table itself. */
    private static boolean isRecursive(Stmt.Cte cte) {
        Stmt.Select s = cte.select();
        if (s.with() != null || s.rest().size() != 1) return false;
        Stmt.CompoundPart part = s.rest().get(0);
        if (part.op() != Stmt.CompoundOp.UNION && part.op() != Stmt.CompoundOp.UNION_ALL) return false;
        return mentions(part.select().from(), cte.name());
    }

    /** True if a table of FROM (not one inside a subquery) has this name. */
    private static boolean mentions(Stmt.From from, String name) {
        if (from == null) return false;
        if (refersTo(from.first(), name)) return true;
        for (Stmt.Join j : from.joins()) if (refersTo(j.item(), name)) return true;
        return false;
    }

    private static boolean refersTo(Stmt.FromItem item, String name) {
        return item instanceof Stmt.TableRef t && t.table().equalsIgnoreCase(name);
    }
}
