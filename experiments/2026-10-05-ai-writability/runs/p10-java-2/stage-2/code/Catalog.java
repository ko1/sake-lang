import java.util.HashMap;
import java.util.Map;

/** The database: all tables by case-insensitive name. */
final class Catalog {
    private final Map<String, Table> tables = new HashMap<>();

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

    void add(Table t) {
        tables.put(Table.key(t.name), t);
    }

    void remove(String name) {
        tables.remove(Table.key(name));
    }
}
