package sqlengine.exec;

import java.util.LinkedHashMap;
import java.util.Map;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;

/**
 * The in-memory database: tables and views (one name space, 5.3) and the indexes of the tables
 * (their own name space, 5.7).
 */
public final class Database {
    private final Map<String, Table> tables = new LinkedHashMap<>();
    private final Map<String, View> views = new LinkedHashMap<>();

    public Table find(String name) {
        return tables.get(Names.norm(name));
    }

    /** The table, or "no such table" with the name as the statement wrote it. */
    public Table require(String name) {
        Table t = find(name);
        if (t == null) throw new SqlError("no such table: " + name);
        return t;
    }

    public void add(Table t) {
        tables.put(Names.norm(t.name), t);
    }

    public void remove(String name) {
        tables.remove(Names.norm(name));
    }

    /** Renames a table (the caller has checked the new name is free). */
    void rename(Table t, String newName) {
        tables.remove(Names.norm(t.name));
        t.name = newName;
        tables.put(Names.norm(newName), t);
    }

    View findView(String name) {
        return views.get(Names.norm(name));
    }

    void addView(View v) {
        views.put(Names.norm(v.name()), v);
    }

    void removeView(String name) {
        views.remove(Names.norm(name));
    }

    /** The table that has an index of this name, or null. */
    Table tableWithIndex(String indexName) {
        for (Table t : tables.values()) {
            if (t.findIndex(indexName) != null) return t;
        }
        return null;
    }

    /** True if a table, a view or an index has this name. */
    boolean nameTaken(String name) {
        return find(name) != null || findView(name) != null || tableWithIndex(name) != null;
    }

    /** An independent copy of the whole state, for ROLLBACK (5.5). */
    Database snapshot() {
        Database copy = new Database();
        for (Table t : tables.values()) copy.add(t.copy());
        copy.views.putAll(views);
        return copy;
    }

    /** Makes this database hold exactly what snapshot holds. */
    void restore(Database snapshot) {
        tables.clear();
        tables.putAll(snapshot.tables);
        views.clear();
        views.putAll(snapshot.views);
    }
}
