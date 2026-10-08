package sqlengine.exec;

import java.util.LinkedHashMap;
import java.util.Map;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;

/** The in-memory database: the set of tables. */
public final class Database {
    private final Map<String, Table> tables = new LinkedHashMap<>();

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
}
