import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * The database schema and data: tables, views and indexes, each by case-insensitive name. A Catalog made
 * by withCtes is an overlay that shares the same tables but also sees WITH tables (which hide the rest).
 */
final class Catalog {
    /** A view: name as created, optional column names, and the select it runs. */
    record View(String name, List<String> columns, Stmt.Select select) {}

    /** An index: name as created, the table's current name, and its unique key (null if not UNIQUE). */
    record Index(String name, String table, Table.UniqueKey unique) {}

    /** A WITH table: the plan producing its rows and its column names. */
    record Cte(QueryPlan plan, List<String> names) {}

    /** Everything a ROLLBACK restores. */
    record Snapshot(Map<String, Table> tables, Map<String, View> views, Map<String, Index> indexes) {}

    private final Map<String, Table> tables;
    private final Map<String, View> views;
    private final Map<String, Index> indexes;
    private final Map<String, Cte> ctes;
    private final Catalog base;

    Catalog() {
        this(new HashMap<>(), new HashMap<>(), new HashMap<>(), Map.of(), null);
    }

    private Catalog(Map<String, Table> tables, Map<String, View> views, Map<String, Index> indexes,
                    Map<String, Cte> ctes, Catalog base) {
        this.tables = tables;
        this.views = views;
        this.indexes = indexes;
        this.ctes = ctes;
        this.base = base == null ? this : base;
    }

    // ---- WITH tables ----

    /** This catalog plus one more WITH table (hiding anything of that name). */
    Catalog withCte(String name, Cte cte) {
        Map<String, Cte> merged = new HashMap<>(ctes);
        merged.put(Table.key(name), cte);
        return new Catalog(tables, views, indexes, merged, base);
    }

    /** The WITH table, or null. */
    Cte cte(String name) {
        return ctes.get(Table.key(name));
    }

    /** The catalog without WITH tables (what a view's select sees). */
    Catalog base() {
        return base;
    }

    // ---- tables and views ----

    /** The table, or null. */
    Table find(String name) {
        return tables.get(Table.key(name));
    }

    /** The table, or the "no such table" error spelled as the statement wrote the name. */
    Table get(String name) {
        Table t = find(name);
        if (t == null) throw new SqlError("no such table: " + name);
        return t;
    }

    /** The table for INSERT / UPDATE / DELETE: a view is "cannot modify". */
    Table getForWrite(String name) {
        View v = view(name);
        if (v != null) throw new SqlError("cannot modify " + v.name() + " because it is a view");
        return get(name);
    }

    void add(Table t) {
        tables.put(Table.key(t.name), t);
    }

    /** Removes the table and its indexes. */
    void remove(String name) {
        Table t = tables.remove(Table.key(name));
        if (t != null) indexes.values().removeIf(i -> Table.key(i.table()).equals(Table.key(t.name)));
    }

    /** The view, or null. */
    View view(String name) {
        return views.get(Table.key(name));
    }

    void addView(View v) {
        views.put(Table.key(v.name()), v);
    }

    void removeView(String name) {
        views.remove(Table.key(name));
    }

    /** True if a table or a view has this name. */
    boolean relationExists(String name) {
        return find(name) != null || view(name) != null;
    }

    // ---- indexes ----

    Index index(String name) {
        return indexes.get(Table.key(name));
    }

    void addIndex(Index i) {
        indexes.put(Table.key(i.name()), i);
    }

    /** Drops the index; its uniqueness constraint leaves the table with it. */
    void removeIndex(String name) {
        Index i = indexes.remove(Table.key(name));
        if (i != null && i.unique() != null) find(i.table()).uniques.removeIf(u -> u == i.unique());
    }

    // ---- ALTER TABLE ----

    /** Renames the table; its indexes follow. */
    void renameTable(Table t, String newName) {
        tables.remove(Table.key(t.name));
        String old = Table.key(t.name);
        t.name = newName;
        tables.put(Table.key(newName), t);
        for (Map.Entry<String, Index> e : new ArrayList<>(indexes.entrySet())) {
            Index i = e.getValue();
            if (Table.key(i.table()).equals(old)) e.setValue(new Index(i.name(), newName, i.unique()));
        }
    }

    // ---- transactions ----

    Snapshot snapshot() {
        Map<String, Table> copy = new HashMap<>();
        tables.forEach((k, t) -> copy.put(k, t.copy()));
        return new Snapshot(copy, new HashMap<>(views), new HashMap<>(indexes));
    }

    void restore(Snapshot s) {
        tables.clear();
        tables.putAll(s.tables());
        views.clear();
        views.putAll(s.views());
        indexes.clear();
        indexes.putAll(s.indexes());
    }
}
