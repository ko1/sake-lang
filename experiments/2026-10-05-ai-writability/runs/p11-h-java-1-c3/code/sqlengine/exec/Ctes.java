package sqlengine.exec;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.function.Supplier;
import sqlengine.parse.Ast.Cte;
import sqlengine.parse.Ast.With;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;

/**
 * The WITH-defined sources visible at some point of a query (5.2). Immutable; a definition is compiled
 * each time it is used, so an unused cte is never checked.
 */
final class Ctes {
    static final Ctes NONE = new Ctes(Map.of());

    private final Map<String, Supplier<Relation>> byName;

    private Ctes(Map<String, Supplier<Relation>> byName) {
        this.byName = byName;
    }

    /** These ctes plus one more (hiding a visible one of the same name). */
    Ctes plus(String name, Supplier<Relation> relation) {
        Map<String, Supplier<Relation>> m = new HashMap<>(byName);
        m.put(Names.norm(name), relation);
        return new Ctes(m);
    }

    /** The relation a name stands for, or null if it is not a cte. */
    Relation find(String name) {
        Supplier<Relation> s = byName.get(Names.norm(name));
        return s == null ? null : s.get();
    }

    /** The ctes visible inside a select with this WITH clause (null: none), on top of outer. */
    static Ctes declare(Database db, Ctes outer, With with) {
        if (with == null) return outer;
        Set<String> seen = new HashSet<>();
        Ctes visible = outer;
        for (Cte c : with.ctes()) {
            if (!seen.add(Names.norm(c.name()))) throw new SqlError("duplicate WITH table name: " + c.name());
            Ctes before = visible; // a cte sees the ones before it (and itself only when recursive)
            boolean recursive = with.recursive() && RecursiveQuery.isRecursive(c);
            visible = visible.plus(c.name(), () -> {
                Query q = recursive ? RecursiveQuery.compile(db, before, c)
                    : QueryCompiler.compile(db, before, c.select(), null);
                return Relation.of(q, c.columns(), "table " + c.name());
            });
        }
        return visible;
    }
}
